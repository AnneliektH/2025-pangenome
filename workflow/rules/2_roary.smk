# run prokka
rule prokka:
    input:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/drep.check",
        genomes= f"{OUTPUT_DIR}/{pang_name_out}/drep/dereplicated_genomes/{{genome}}.fasta",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.done",
    conda: 
        "prokka"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{genome}}"
    shell:
        """ 
        prokka --kingdom Bacteria --outdir {params.output_folder} \
        --norrna --notrna --prefix {wildcards.genome} --force \
        --locustag {wildcards.genome} {input.genomes} && touch {output.check}
        """

# run roary
rule roary:
    input:
        prokka_done = expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.done", genome=genomes)
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done",
    conda: 
        "roary"
    threads: 24
    params:
        prokka_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka",
        gff_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka/gff",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/roary"
    shell:
        """ 
        mkdir -p {params.gff_folder} && \
        cp {params.prokka_folder}/*/*.gff {params.gff_folder} && \
        roary -p {threads} -f {params.output_folder} \
        -e -n -v {params.gff_folder}/*.gff && touch {output.check}
        """

