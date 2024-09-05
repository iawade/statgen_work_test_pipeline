# Snakemake workflow to execute GWAS pipeline

# Target Rule for Completion of Pipeline
rule all:
    input:
        "{project_name}_normality_test.csv".format(project_name=config["project_name"]),
	"{project_name}_bgzip.vcf.gz.tbi".format(project_name=config["project_name"]),
        "{project_name}_bgzip_mono_snp.vcf.gz.tbi".format(project_name=config["project_name"]),
	"{project_name}_bgzip_mono_snp_filltags.vcf.gz".format(project_name=config["project_name"]),
        "{project_name}_bgzip_mono_snp_filltags.vcf.gz.tbi".format(project_name=config["project_name"]),
	"{project_name}_sample_qc.vcf.gz.tbi".format(project_name=config["project_name"]),
        "{project_name}_sample_qc_site_qc_labelled.vcf.gz.tbi".format(project_name=config["project_name"]),
        "{project_name}_sample_qc_site_qc_applied.vcf.gz.tbi".format(project_name=config["project_name"]),
	"{project_name}_manhattan.pdf".format(project_name=config["project_name"]),
        "{project_name}_qq.pdf".format(project_name=config["project_name"]),
    output:
        "pipeline_complete.txt"
    shell:
        "touch {output}"

# Prepare Data

## Check for phenotype normality
rule check_pheno: # this rule would run better with an exception
    input:
        phenotype_file=config["phenotype_file"]
    output:
        "{project_name}_normality_test.csv",
    params:
        project_name = config["project_name"],
    shell:
        """
        Rscript ../../scripts/check_phenotype_normality.R {input.phenotype_file} {output}
        """

## Index and re bgzip if necessary
rule check_vcf: # would also want to check for uncompressed
    input:
        input_vcf=config["input_vcf"]
    output:
        "{project_name}_bgzip.vcf.gz",
	"{project_name}_bgzip.vcf.gz.tbi",
    params:
        project_name = config["project_name"],
    shell:
        "bash ../../scripts/vcf_format_check.sh {input.input_vcf} {output[0]}"

## Restrict based on type of variants to analyse
### This doesn't actually have functionality I'd want - choose a profile (monoallelic snps or all snos, etc)
rule check_variant_type:
    input:
        "{project_name}_bgzip.vcf.gz",
    output:
        "{project_name}_bgzip_mono_snp.vcf.gz",
	"{project_name}_bgzip_mono_snp.vcf.gz.tbi",
    params:
        project_name = config["project_name"],
    shell:
        "bash ../../scripts/vcf_variants_check.sh {input} {output[0]}"


## fill tags
rule vcf_fill_tags:
    input:
        "{project_name}_bgzip_mono_snp.vcf.gz",
    output:
        "{project_name}_bgzip_mono_snp_filltags.vcf.gz",
        "{project_name}_bgzip_mono_snp_filltags.vcf.gz.tbi",
    params:
        project_name = config["project_name"],
    shell:
        "bash ../../scripts/vcf_filltags.sh {input} {output[0]}"


# Sample QC

## sample stats
rule sample_stats:
    input:
        "{project_name}_bgzip_mono_snp_filltags.vcf.gz",
    output:
        "{project_name}_sample_stats.txt",
    params:
        project_name = config["project_name"],
    shell:
        "bash ../../scripts/vcf_stats.sh {input} {output}"


## sample genotyping rate fails
rule sample_qc_genotype_missing:
    input:
        "{project_name}_sample_stats.txt",
    output:
        "{project_name}_sample_qc_genotyping_fail.txt",
    params:
        project_name = config["project_name"],
	sample_genotype_missing_cutoff = config["sample_genotype_missing_cutoff"]
    shell:
        "bash ../../scripts/sample_qc_genotyping.sh {input} {output} {params.sample_genotype_missing_cutoff}"

## Sample Excess Heterozygosity fail
rule sample_qc_excess_het:
    input:
        "{project_name}_sample_stats.txt",
    output:
        "{project_name}_sample_qc_excess_het_fail.txt",
    params:
        project_name = config["project_name"],
	sample_excess_het_mad_cutoff = config["sample_excess_het_mad_cutoff"]
    shell:
        """
	grep ^PSC {input} > input_for_R.txt && \
	Rscript ../../scripts/sample_qc_excess_het.R input_for_R.txt {output} {params.sample_excess_het_mad_cutoff} \
	&& rm input_for_R.txt
	"""

## Remove samples that fail
rule sample_qc_filter:
    input:
        "{project_name}_bgzip_mono_snp_filltags.vcf.gz",
	"{project_name}_sample_qc_genotyping_fail.txt",
	"{project_name}_sample_qc_excess_het_fail.txt",
    output:
        "{project_name}_sample_qc.vcf.gz",
	"{project_name}_sample_qc.vcf.gz.tbi"
    params:
        project_name = config["project_name"],
    shell:
        "bash ../../scripts/filter_sample_qc_fails.sh {input[0]} {output[0]} {input[1]} {input[2]}"

# Site QC

## Label pass-fail
rule update_filter:
    input:
        "{project_name}_sample_qc.vcf.gz",
    output:
        "{project_name}_sample_qc_site_qc_labelled.vcf.gz",
	"{project_name}_sample_qc_site_qc_labelled.vcf.gz.tbi",
    params:
        project_name = config["project_name"],
	site_genotype_missing_cutoff = config["site_genotype_missing_cutoff"],
	site_excess_het_cutoff = config["site_excess_het_cutoff"],
	HWE_cutoff = config["HWE_cutoff"],
	MAF_cutoff = config["MAF_cutoff"],
    shell:
        """
	bash ../../scripts/site_qc_update_filter_field.sh {input} {output[0]} \
	{params.site_genotype_missing_cutoff} \
	{params.site_excess_het_cutoff} \
	{params.HWE_cutoff} \
	{params.MAF_cutoff} \
	"""
## Filter VCF
rule apply_site_qc_filter:
    input:
        "{project_name}_sample_qc_site_qc_labelled.vcf.gz",
    output:
        "{project_name}_sample_qc_site_qc_applied.vcf.gz",
        "{project_name}_sample_qc_site_qc_applied.vcf.gz.tbi",
    params:
        project_name = config["project_name"],
    shell:
        "bash ../../scripts/filter_site_qc_fails.sh {input} {output[0]} "

# GWAS

## Convert to plink, add phenotype, calculate linear regression
rule calculate_regression:
    input:
        "{project_name}_sample_qc_site_qc_applied.vcf.gz",
    output:
        "{project_name}_glm_linear_for_plot.tsv",
    params:
        project_name = config["project_name"],
	phenotype_file=config["phenotype_file"],
    shell:
        "bash ../../scripts/calculate_regression.sh {input} {output[0]} {params.phenotype_file} "

## Plot
rule plot_results:
    input:
        "{project_name}_glm_linear_for_plot.tsv",
    output:
        "{project_name}_manhattan.pdf",
	"{project_name}_qq.pdf",
    params:
        project_name = config["project_name"],
    shell:
        "Rscript ../../scripts/plot_gwas.R {input} {output[0]} {output[1]} "

