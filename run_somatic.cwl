class: Workflow
cwlVersion: v1.0
id: run_somatic
label: run_somatic

inputs:
  reference_sequence:
    type: File
    secondaryFiles:
      - .amb
      - .ann
      - .bwt
      - .pac
      - .sa
      - .fai
      - ^.dict

  tumor_bam:
    type: File
    secondaryFiles:
      - ^.bai

  normal_bam:
    type: File
    secondaryFiles:
      - ^.bai

  facets_vcf:
    type: File
    secondaryFiles:
      - .gz

  normal_id:
    type: string

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

  delly_params:
    type:
      type: record
      fields:
        svtype: string[]
        delly_exclude: File

  msisensor_list:
    type: File

outputs:
  dir_somatic:
    type: Directory
    outputSource: put_in_dir_somatic/directory

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

  run_msisensor:
    in:
      d: msisensor_list
      t: tumor_bam
      n: normal_bam
      o:
        valueFrom: ${ return inputs.t.basename.replace(".bam","") + "_" + inputs.t.basename.replace(".bam","") + ".msisensor.tsv"; }
    out: [ output ]
    run: msisensor_0.5/msisensor.cwl

  run_delly:
    in:
      params: delly_params
      svtype:
        valueFrom: $(inputs.params.svtype)
      exclude: 
        valueFrom: $(inputs.params.exclude)
      id_tumor: tumor_id 
      id_normal: normal_id
      bam_tumor: tumor_bam
      bam_normal: normal_bam
      genome: reference_sequence
    out: [ delly_filtered_output ]
    run: delly_workflow/run_delly.cwl
      
  put_in_dir_facets:
    in:
      files:
        source: [ run_facets/facets_out_files, run_facets/facets_png, run_facets/facets_rdata, run_facets/facets_seg, run_facets/facets_txt_hisens, run_facets/facets_txt_purity ] 
        linkMerge: merge_flattened 
      output_directory_name:
        valueFrom: ${ return "facets"; }
    out: [ directory ]
    run: utils/put_files_in_dir.cwl

  put_in_dir_msisensor:
    in:
      files:
        source: [ run_msisensor/output ] 
        linkMerge: merge_flattened 
      output_directory_name:
        valueFrom: ${ return "msisensor"; }
    out: [ directory ]
    run: utils/put_files_in_dir.cwl

  put_in_dir_delly:
    in:
      files:
        source: [ run_delly/delly_filtered_output ] 
        linkMerge: merge_flattened 
      output_directory_name:
        valueFrom: ${ return "delly"; }
    out: [ directory ]
    run: utils/put_files_in_dir.cwl

  put_in_dir_somatic:
    in:
      files:
        source: [ put_in_dir_facets/directory, put_in_dir_msisensor/directory, put_in_dir_delly/directory ]
      output_directory_name: 
        valueFrom: ${ return "somatic"; }
    out: [ directory ]
    run: utils/put_files_in_dir.cwl

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
