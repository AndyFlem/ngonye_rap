BEGIN;

CREATE TABLE public.vas_surveys (
    vas_id                         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pah                            VARCHAR(9) REFERENCES public.households(pah),
    survey_date                    TIMESTAMP,
    enumerator                     TEXT,

    -- Section 1: respondent identity is on the person table
    respondent_person_id           BIGINT REFERENCES public.person(person_id),

    -- Section 2: Household Composition
    hh_total_members               SMALLINT,
    hh_children_0_17               SMALLINT,
    hh_adults_18_64                SMALLINT,
    hh_elderly_65_plus             SMALLINT,
    hh_disabled_count              SMALLINT,
    hh_head_type                   VARCHAR(20),
    hh_single_income_dependents    BOOLEAN,

    -- Section 3: Vulnerability Screening — Economic
    vuln_no_regular_income         BOOLEAN,
    vuln_below_subsistence         BOOLEAN,
    vuln_informal_seasonal         BOOLEAN,
    vuln_no_productive_assets      BOOLEAN,

    -- Section 3: Vulnerability Screening — Social
    vuln_female_headed             BOOLEAN,
    vuln_child_headed              BOOLEAN,
    vuln_elderly_headed            BOOLEAN,
    vuln_orphaned_children         BOOLEAN,

    -- Section 3: Vulnerability Screening — Health
    vuln_chronically_ill           BOOLEAN,
    vuln_disability                BOOLEAN,
    vuln_limited_healthcare        BOOLEAN,
    vuln_malnutrition              BOOLEAN,

    -- Section 3: Vulnerability Screening — Physical
    vuln_poor_housing              BOOLEAN,
    vuln_no_clean_water            BOOLEAN,
    vuln_no_sanitation             BOOLEAN,
    vuln_remote_location           BOOLEAN,

    -- Section 4: Livelihoods and Income
    livelihood_main                VARCHAR(50),
    livelihood_main_other          TEXT,
    monthly_income                 NUMERIC(12,2),
    livelihood_project_affected    BOOLEAN,
    livelihood_impact_desc         TEXT,
    livelihood_has_alternative     BOOLEAN,

    -- Section 5: Land and Asset Ownership
    owns_land                      BOOLEAN,
    land_tenure                    VARCHAR(20),
    assets_house                   BOOLEAN,
    assets_livestock               BOOLEAN,
    assets_crops                   BOOLEAN,
    assets_business                BOOLEAN,
    assets_tools                   BOOLEAN,
    assets_project_affected        BOOLEAN,

    -- Section 6: Access to Services
    health_facility_name           TEXT,
    distance_health_km             NUMERIC(8,2),
    school_name                    TEXT,
    distance_school_km             NUMERIC(8,2),
    distance_water_km              NUMERIC(8,2),
    has_clean_water                BOOLEAN,
    has_solar                      BOOLEAN,
    has_electricity                BOOLEAN,
    has_sanitation                 BOOLEAN,

    -- Section 7: Coping Capacity and Support Systems
    support_government             BOOLEAN,
    support_ngo                    BOOLEAN,
    support_family                 BOOLEAN,
    support_none                   BOOLEAN,
    cope_savings                   BOOLEAN,
    cope_borrowing                 BOOLEAN,
    cope_sell_assets               BOOLEAN,
    cope_relatives                 BOOLEAN,
    community_group_member         BOOLEAN,
    community_group_name           TEXT,

    -- Section 8: Project Impact Perception
    project_concerns               TEXT,
    support_needed_financial       BOOLEAN,
    support_needed_livelihood      BOOLEAN,
    support_needed_skills          BOOLEAN,
    support_needed_health          BOOLEAN,
    support_needed_other           TEXT,

    -- Section 9: Special Assistance Needs
    assistance_livelihood          BOOLEAN,
    assistance_health_social       BOOLEAN,
    assistance_other               TEXT,

    -- Section 10: Enumerator's Assessment
    enumerator_is_vulnerable       BOOLEAN,
    enumerator_vulnerability_types TEXT,
    enumerator_recommended_support TEXT,

    survey_link                    TEXT,
    created_at                     TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_vas_surveys_pah ON public.vas_surveys(pah);

COMMIT;
