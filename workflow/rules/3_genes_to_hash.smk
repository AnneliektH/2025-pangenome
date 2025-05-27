# after roary: use script to get genes of interest
# run roary
rule roary_split:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done",
        check_all = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.all.done",
    output:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
        csv_all = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks_all.csv",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary",
        roary_all_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary_all",
    shell:
        """ 
        python scripts/count_genes.py {params.roary_folder}/gene_presence_absence.Rtab \
        {output.csv} {params.roary_folder}/ && \
        python scripts/count_genes.py {params.roary_all_folder}/gene_presence_absence.Rtab \
        {output.csv_all} {params.roary_all_folder}/
        """

rule split_fasta:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks.csv",
        csv_all = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.generanks_all.csv",
    output:
         core_fa = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}.core.gtdb.fa",
         cloud_fa = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}.cloud.gtdb.fa",
         core_fa_all = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}.core.all.fa",
         cloud_fa_all = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}.cloud.all.fa",
    conda: 
        "seqkit"
    threads: 1
    params:
        roary_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary",
        roary_all_folder = f"{OUTPUT_DIR}/{pang_name_out}/roary_all",
    shell:
        """ 
        seqkit grep -n -r -f {params.roary_folder}/hard_core.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.core_fa} && \
        seqkit grep -n -r -f {params.roary_folder}/cloud.txt \
        {params.roary_folder}/pan_genome_reference.fa -o {output.cloud_fa} && \
        seqkit grep -n -r -f {params.roary_all_folder}/hard_core.txt \
        {params.roary_all_folder}/pan_genome_reference.fa -o {output.core_fa_all} && \
        seqkit grep -n -r -f {params.roary_all_folder}/cloud.txt \
        {params.roary_all_folder}/pan_genome_reference.fa -o {output.cloud_fa_all} 
        """


rule sketch:
    input:
         core_fa = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}.core.gtdb.fa",
         cloud_fa = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}.cloud.gtdb.fa",
         core_fa_all = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}.core.all.fa",
         cloud_fa_all = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}.cloud.all.fa",
    output:
         core_sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.core.gtdb.zip",
         cloud_sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.cloud.gtdb.zip",
         core_sig_all = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.core.all.zip",
         cloud_sig_all = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.cloud.all.zip",
         core_sig_tr = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.core.tr.gtdb.zip",
         cloud_sig_tr = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.cloud.tr.gtdb.zip",
         core_sig_all_tr = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.core.tr.all.zip",
         cloud_sig_all_tr = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.cloud.tr.all.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """ 
        sourmash sketch dna {input.core_fa} -o {output.core_sig} -p k=21,scaled=1000 && \
        sourmash sketch dna {input.cloud_fa} -o {output.cloud_sig} -p k=21,scaled=1000 && \
        sourmash sketch dna {input.core_fa_all} -o {output.core_sig_all} -p k=21,scaled=1000 && \
        sourmash sketch dna {input.cloud_fa_all} -o {output.cloud_sig_all} -p k=21,scaled=1000 && \
        sourmash sketch translate {input.core_fa} -o {output.core_sig_tr} -p k=10,scaled=500 && \
        sourmash sketch translate {input.cloud_fa} -o {output.cloud_sig_tr} -p k=10,scaled=500 && \
        sourmash sketch translate {input.core_fa_all} -o {output.core_sig_all_tr} -p k=10,scaled=500 && \
        sourmash sketch translate {input.cloud_fa_all} -o {output.cloud_sig_all_tr} -p k=10,scaled=500
        """