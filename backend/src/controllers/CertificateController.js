const fs = require('fs')
const path = require('path')
const { createReport } = require('docx-templates')
const Knex = require('../services/db')
const Common = require('./CommonDebug')('Certificate')

const TEMPLATE_PATH = path.join(__dirname, '..', '..', 'templates', 'ica_template_2026_01.docx')
const TEMPLATE_PATH_NHS = path.join(__dirname, '..', '..', 'templates', 'f_ica_template_2026_01.docx')

const fmtm2 = (v) => (v != null ? Number(v).toLocaleString('en-GB', { minimumFractionDigits: 0, maximumFractionDigits: 0 }) : '0') + ' m²'
const fmtZMW = (v) => 'K' + (v != null ? Number(v).toLocaleString('en-GB', { minimumFractionDigits: 0, maximumFractionDigits: 0 }) : '0')
//const yesNo = (v) => v ? 'Yes' : 'No'
const fmtDate = (d, opts) => d ? new Date(d).toLocaleDateString('en-GB', opts || {}) : ''

module.exports = {
  async generate (req, res) {
    const { pah } = req.params
    Common.debug(req, 'generate', pah)

    if (!pah) return res.status(400).send({ error: 'pah is required' })

    try {
      const household = await Knex('v_households').where({ pah }).first()
      household.primary_structures_value = fmtZMW(household.primary_structures_value)
      household.secondary_structures_compensation_value = fmtZMW(household.secondary_structures_compensation_value)
      household.crop_size = fmtm2(household.crop_size)
      household.crop_value = fmtZMW(household.crop_value)
      household.trees_compensation = fmtZMW(household.trees_compensation)
      household.allowance_disturbance_fmt = fmtZMW(household.allowance_disturbance)
      household.allowance_transitional_fmt = fmtZMW(household.allowance_transitional)
      household.allowance_transport_fmt = fmtZMW(household.allowance_transport)
      household.allowance_landprep_fmt = fmtZMW(household.allowance_landprep)
      household.allowance_business_fmt = fmtZMW(household.allowance_business)
      household.allowance_rental_fmt = fmtZMW(household.allowance_rental)

      if (!household) return res.status(404).send({ error: 'household not found' })

      const [survey, landCompensation, landPermanent,structures, crops, trees, graves] = await Promise.all([
        Knex('households_survey').where({ pah }).first(),
        Knex('v_household_land_compensation').where({ pah }).orderBy('acquisition_class').orderBy('rate_acquisition_class'),
        Knex('v_household_land_permanent').where({ pah }),
        //Knex('v_land_parcels').where({ pah }),
        Knex('v_structures').where({ pah }).orderBy('structure_class').orderBy('structure_type'),
        Knex('v_crops').where({ pah }).orderBy('crop_type'),
        Knex('v_trees_summary').where({ pah }).orderBy('tree_type'),
        Knex('v_graves').where({ pah })
      ])

      //const parcelMap = Object.fromEntries((landParcels || []).map(p => [p.land_parcel_id, p]))
      const primaryStructures = (structures || []).filter(s => s.structure_class === 'Primary Structure').map(s => {
        s.structure_value = fmtZMW(s.structure_value)
        s.dimensions = (s.dimensions && s.dimensions > 0) ? fmtm2(s.dimensions) : ''
        return s
      })
      const secondaryStructures = (structures || []).filter(s => s.structure_class === 'Secondary Structure').map(s => {
        s.rooms = (s.rooms && s.rooms > 0) ? s.rooms : ''
        s.structure_value = fmtZMW(s.structure_value)
        s.dimensions = (s.dimensions && s.dimensions > 0) ? fmtm2(s.dimensions) : ''
        return s
      })

      // const landCompensationMap = Object.fromEntries((landCompensation || []).map(lc => {
      //   lc.area_sqm = fmtm2(lc.area_sqm)
      //   lc.land_value = fmtZMW(lc.land_value)
      //   return [lc.acquisition_class + lc.rate_acquisition_class, lc]
      // }
      // ))

      const landCompensationPermanent = (landCompensation || []).filter(lp => lp.acquisition_class === 'Permanent').map(lc => {
        lc.area_sqm = fmtm2(lc.area_sqm)
        lc.land_value = fmtZMW(lc.land_value)
        return lc
      })
      const landCompensationTemporary = (landCompensation || []).filter(lp => lp.acquisition_class === 'Temporary').map(lc => {
        lc.area_sqm = fmtm2(lc.area_sqm)
        
        lc.lease_cost = fmtZMW(lc.lease_cost)
        lc.lease_cost_total = fmtZMW(lc.lease_cost_total)
        return lc
      })      
      const landPermanentMap = Object.fromEntries((landPermanent || []).map(lp => {
        lp.area_sqm = fmtm2(lp.area_sqm)
        lp.land_value = fmtZMW(lp.land_value)
        return [lp.land_class, lp]
      }
      ))

      const cropsList = (crops || []).map(c => {
        c.crop_value = fmtZMW(c.crop_value)
        c.crop_size = fmtm2(c.crop_size)
        c.rate = fmtZMW(c.rate)
        return c
      })
      const treesList = (trees || []).map(t => {
        t.compensation = fmtZMW(t.compensation)
        return t
      })

      const data = {
        pah: pah,
        household: household,
        survey: survey,
        //landCompensation: landCompensationMap,
        landCompensationPermanent: landCompensationPermanent,
        landCompensationTemporary: landCompensationTemporary,
        landPermanent: landPermanentMap,
        primaryStructures: primaryStructures,
        secondaryStructures: secondaryStructures,
        crops: cropsList,
        trees: treesList,
        graves: graves,
        generation_date: fmtDate(new Date(), { day: '2-digit', month: 'long', year: 'numeric' })
      }

      // Debug section — split JSON into one array entry per line for the template loop
      data.debug_lines = JSON.stringify(data, null, 2).split('\n')

      const template = fs.readFileSync(TEMPLATE_PATH)
      const buffer = await createReport({ template, data, cmdDelimiter: ['{{', '}}'] })

      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      res.setHeader('Content-Disposition', `attachment; filename="${pah}.docx"`)
      return res.send(Buffer.from(buffer))

    } catch (err) {
      Common.error(req, 'generate', err)
      return res.status(500).send({ error: `certificate generation failed: ${err.message}` })
    }
  },
  async generateFisher (req, res) {
    const { nhs } = req.params
    Common.debug(req, 'generate', nhs)

    if (!nhs) return res.status(400).send({ error: 'nhs is required' })

    try {
      const fisher = await Knex('v_fishers').where({ nhs }).first()


      if (!fisher) return res.status(404).send({ error: 'fisher not found' })

      // const [survey, landCompensation, landPermanent,structures, crops, trees, graves] = await Promise.all([
      //   Knex('households_survey').where({ pah }).first(),
      //   Knex('v_household_land_compensation').where({ pah }).orderBy('acquisition_class').orderBy('rate_acquisition_class'),
      //   Knex('v_household_land_permanent').where({ pah }),
      //   //Knex('v_land_parcels').where({ pah }),
      //   Knex('v_structures').where({ pah }).orderBy('structure_class').orderBy('structure_type'),
      //   Knex('v_crops').where({ pah }).orderBy('crop_type'),
      //   Knex('v_trees_summary').where({ pah }).orderBy('tree_type'),
      //   Knex('v_graves').where({ pah })
      // ])

      fisher.site_compensation = fmtZMW(fisher.site_compensation)
      fisher.maungwe_annual_earnings = fmtZMW(fisher.maungwe_annual_earnings)
      fisher.limbelo_annual_earnings = fmtZMW(fisher.limbelo_annual_earnings)
      fisher.transitional_allowance = fmtZMW(fisher.transitional_allowance)

      const data = {
        fisher: fisher,
        generation_date: fmtDate(new Date(), { day: '2-digit', month: 'long', year: 'numeric' })
      }

      // Debug section — split JSON into one array entry per line for the template loop
      data.debug_lines = JSON.stringify(data, null, 2).split('\n')

      const template = fs.readFileSync(TEMPLATE_PATH_NHS)
      const buffer = await createReport({ template, data, cmdDelimiter: ['{{', '}}'] })

      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      res.setHeader('Content-Disposition', `attachment; filename="ICA_${nhs}.docx"`)
      return res.send(Buffer.from(buffer))

    } catch (err) {
      Common.error(req, 'generate', err)
      return res.status(500).send({ error: `certificate generation failed: ${err.message}` })
    }
  },  
}
