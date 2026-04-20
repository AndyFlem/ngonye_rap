import { format } from 'd3'

export default {
  install: (app) => {
    const formatKwacha = (val) => {
      if (!isNaN(parseFloat(val))) {
        return (val < 0 ? '(' : '') + 'K' + format(',.2f')(Math.abs(val)) + (val < 0 ? ')' : '')
      } else {
        return 'K' + ' -'
      }
    }
    app.provide('formatKwacha', formatKwacha)

    const formatArea = (val) => {
      if (!isNaN(parseFloat(val))) {
        return format(',.3n')(val/10000) + ' ha'
      } else {
        return '-'
      }
    }
    app.provide('formatArea', formatArea)

    const formatPct = (val) => {
      if (!isNaN(parseFloat(val))) {
        return format(',.0%')(val)
      } else {
        return '-'
      }
    }
    app.provide('formatPct', formatPct)
  }
}

// function formatDollar(val) {
//   if (!isNaN(parseFloat(val))) {
//     return '$' + format(',.0f')(val)
//   } else {
//     return '$ -'
//   }
// }
