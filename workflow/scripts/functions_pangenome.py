# replace spaces with underscores
def format_species_name(species):
    return species.replace(' ', '_')

# for creatong the dmp files
# we want all signatures of metaGs x one microbial species
def calc_hash_input(wildcards):
    files = expand("/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig", metag=METAGS)
    with open("input_files.txt", "w") as f:
        for file in files:
            f.write(f"{file}\n")
    return "input_files.txt"

# Get input for signatures, either human or pig
# Human are in wort data, pig are in own sketch files
def get_input_file_path(metag):
    if metag in HUMAN_METAG:
        return "/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    elif metag in PIG_METAG:
        return "/group/ctbrowngrp2/scratch/annie/2023-swine-sra/sourmash/sig_files/sketch_reads_s100/{metag}.sig.gz"
    else:
        raise ValueError(f"Unknown sample type: {metag}")

# Function to determine the output directory based on the sample type
def get_output_dir(metag):
    if metag in HUMAN_METAG:
        return "compare_human"
    elif metag in PIG_METAG:
        return "compare_pig"
    else:
        raise ValueError(f"Unknown sample type: {metag}")