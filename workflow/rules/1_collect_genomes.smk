# get lists of MAGs that are org of interest
# 2 lists, one for GTDB and one for own MAGs
rule get_mags_of_interest:
    output:
        tsv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xownmags.tsv",
        csv_temp = temp(f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb_temp.csv"),
        csv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb.csv"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """ 
        (head -n 1 {NEW_MAG_TAX} && grep -e "{pangenome_species}" {NEW_MAG_TAX}) > {output.tsv} && \
        (head -n 1 {GTDB_TAX} && grep -e "{pangenome_species}" {GTDB_TAX}) > {output.csv_temp} && \
        python scripts/create_acc.py {output.csv_temp} {output.csv}
        """

# Now create 2 folders, for the MAGs. Once for only reference, one for all
# download MAGs from NCBI with directsketch
rule directsketch:
    input:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb.csv",
    output:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
        failed_test = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.failed.csv",
        fail_checksum= f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.checksum.failed.csv",
    conda: 
        "branchwater-skipmer"
    threads: 10
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs"
    shell:
        """ 
        sourmash scripts gbsketch  --keep-fasta --genomes-only \
        {input.csv} -o {output.sig} -p dna,k=21,k=31,scaled=100,abund \
        -f {params.output_folder} -k -c {threads} \
        --failed {output.failed_test} -r 1 --checksum-fail {output.fail_checksum}
        for f in {params.output_folder}/*.fna.gz; do
            mv "$f" "${{f%.fna.gz}}.fasta"
        done
        """

# symlink pig-specific MAGs
rule symlink_MAGs:
    input:
        tsv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xownmags.tsv",
        #pangenome_species = pangenome_species,
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/symlink.check",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs"
    shell:
        """ 
        python scripts/create_symlink_args.py {input.tsv} {MAG_LOCATION} {params.output_folder} && \
        touch {output.check}
        """

# dereplicate MAGs
rule drep_reference:
    input:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/drep.check",
    conda: 
        "drep"
    threads: 10
    params:
        input_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/drep"
    shell:
        """ 
        dRep dereplicate {params.output_folder} -p {threads} \
        --ignoreGenomeQuality -pa 0.9 -sa 0.99 -nc 0.30 -cm larger \
        -g {params.input_folder}/*genomic.fasta && \
        touch {output.check}
        """

rule drep_all:
    input:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
        check =  f"{OUTPUT_DIR}/{pang_name_out}/check/symlink.check",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/drep_all.check",
    conda: 
        "drep"
    threads: 12
    params:
        input_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/drep_all"
    shell:
        """ 
        dRep dereplicate {params.output_folder} -p {threads} \
        --ignoreGenomeQuality -pa 0.9 -sa 0.99 -nc 0.30 -cm larger \
        -g {params.input_folder}/*.fasta && \
        touch {output.check}
        """