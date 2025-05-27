# run prokka
rule prokka_all:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/drep_all.check",
        genomes= f"{OUTPUT_DIR}/{pang_name_out}/drep_all/dereplicated_genomes/{{genome}}.fasta",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.all.done",
    conda: 
        "prokka"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/prokka_all/{{genome}}"
    shell:
        """ 
        prokka --kingdom Bacteria --outdir {params.output_folder} \
        --norrna --notrna --prefix {wildcards.genome} --force \
        --locustag {wildcards.genome} {input.genomes} && touch {output.check}
        """

# run roary
rule roary_all:
    input:
        prokka_done = expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.all.done", genome=genomes_all)
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.all.done",
    conda: 
        "roary"
    threads: 24
    params:
        prokka_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka_all",
        gff_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka_all/gff",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/roary_all"
    shell:
        """ 
        mkdir -p {params.gff_folder} && \
        cp {params.prokka_folder}/*/*.gff {params.gff_folder} && \
        roary -p {threads} -f {params.output_folder} \
        -e -n -v {params.gff_folder}/*.gff && touch {output.check}
        """

