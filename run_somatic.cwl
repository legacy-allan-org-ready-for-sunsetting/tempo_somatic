class: Workflow
cwlVersion: v1.0
id: run_somatic
label: run_somatic

inputs:
  tumor_bam:
    type: File

  normal_bam:
    type: File

  facets_vcf:
    type: File
    secondaryFiles:
      - .gz

  tumor_id:
    type: string

  facets_params:
    type:
      type: record
      fields:
        pseudo_snps: int
        count_orphans: boolean
        gzip: boolean
        ignore_overlaps: boolean
        max_depth: int
        min_base_quality: int
        min_read_counts: int
        min_map_quality: int
        cval: int
        snp_nbhd: int
        ndepth: int
        min_nhet: int
        purity_cval: int
        purity_snp_nbhd: int
        purity_ndepth: int
        purity_min_nhet: int
        genome: string
        directory: string
        R_lib: string
        single_chrom: string
        ggplot2: string
        seed: int

outputs:
  facets_png:
    type: File[]?
    outputSource: run_facets/facets_png

  facets_txt_purity:
    type: File?
    outputSource: run_facets/facets_txt_purity

  facets_txt_hisens:
    type: File?
    outputSource: run_facets/facets_txt_hisens

  facets_out_files:
    type: File[]?
    outputSource: run_facets/facets_out_files

  facets_rdata:
    type: File[]?
    outputSource: run_facets/facets_rdata

  facets_seg:
    type: File[]?
    outputSource: run_facets/facets_seg
  
steps:
  run_facets:
    in:
      params: facets_params
      bam_normal: normal_bam
      bam_tumor: tumor_bam
      facets_vcf: facets_vcf
      tumor_id: tumor_id
      facets_output_prefix: tumor_id
      snp_pileup_output_file_name:
        valueFrom: ${ return inputs.tumor_id + ".dat.gz" }
    out: [ facets_out_files, facets_png, facets_rdata, facets_seg, facets_txt_hisens, facets_txt_purity ] 
    run: cnv_facets/cnv_facets.cwl

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
