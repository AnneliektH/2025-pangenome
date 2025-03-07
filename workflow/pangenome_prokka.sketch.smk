FASTA, = glob_wildcards('../results/pangenome/l_amylovorus/prokka/ffn/{fasta}.ffn')
PROTFASTA, = glob_wildcards('../results/pangenome/l_amylovorus/prokka/faa/{fasta}.faa')

rule all:
    input:
        expand("../results/pangenome/l_amylovorus/sourmash/prokka_ffn/{fasta}.zip", fasta=FASTA),

# sketch proteins  
rule sketch_protein:
    input:
        fasta = '../results/pangenome/l_amylovorus/prokka/faa/{fasta}.faa',
    output:
        sig= "../results/pangenome/l_amylovorus/sourmash/sketches/{fasta}.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sketch dna {input.fasta} \
        -p k=21,k=31,k=51,scaled=100,abund \
        --name {wildcards.fasta} -o {output.sig}
        """
# sketch dna 
rule sketch:
    input:
        fasta = '../results/pangenome/l_amylovorus/prokka/ffn/{fasta}.ffn',
    output:
        sig= "../results/pangenome/l_amylovorus/sourmash/prokka_ffn/{fasta}.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sketch dna {input.fasta} \
        -p k=21,k=31,k=51,scaled=100,abund \
        --name {wildcards.fasta} -o {output.sig}
        """
