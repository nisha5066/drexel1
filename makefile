all:
	make index
	make pipe sample=jlat
	make pipe sample=U1
	make package

pipe:
	make alignment
	make variants
	make label_variants
	make filter_variants

alignment:
	# Align sequences with minimap
	minimap2 -a -x map-hifi --secondary=no K03455.fasta $(sample).fastq > $(sample).sam
	
	# Sort and index the alignment
	samtools view -s 0.1 -q 20 -bo $(sample).bam $(sample).sam
	samtools sort -o $(sample).sorted.bam $(sample).bam
	samtools index $(sample).sorted.bam    
	
	# Cleanup
	rm $(sample).sam $(sample).bam
    
variants:
	mkdir $(sample) || true
	docker run -it \
		-v /home/jupyter-will/tmp/Week13/:/work \
		hkubal/clair3:latest \
		/opt/bin/run_clair3.sh \
		--bam_fn=/work/$(sample).sorted.bam --ref_fn=/work/K03455.fasta --threads=32 --platform="ont" --model_path="/opt/models/r941_prom_sup_g5014" --output=/work/$(sample) --include_all_ctgs


label_variants:
	snpEff ann -c ~/share/garden/refs/snpeff/snpEff.config  -no-downstream -no-intron -no-upstream -no-utr K03455.1 $(sample)/merge_output.vcf.gz > $(sample)/$(sample).snpeff.vcf
	cp snpEff_genes.txt $(sample)/snpEff_genes.txt
	cp snpEff_summary.html $(sample)/snpEff_summary.html    
    
filter_variants:
	SnpSift filter "( EFF[*].IMPACT = 'HIGH' )" $(sample)/$(sample).snpeff.vcf > $(sample)/$(sample).HIGH.vcf


index:
	samtools faidx K03455.fasta

    
package:
	mkdir Week13-files || true
	cp makefile Week13-files
	cp K03455.fasta K03455.fasta.fai Week13-files
	make pack sample=jlat
	make pack sample=U1	
	zip -r Week13-files.zip Week13-files
pack:
	cp $(sample).sorted.bam $(sample).sorted.bam.bai Week13-files
	zcat $(sample)/merge_output.vcf.gz > Week13-files/$(sample).clair.vcf
	cp $(sample)/$(sample).snpeff.vcf Week13-files
	cp $(sample)/$(sample).HIGH.vcf Week13-files
	cp $(sample)/snpEff_genes.txt Week13-files/$(sample).snpEff_genes.txt
	cp $(sample)/snpEff_summary.html Week13-files/$(sample).snpEff_summary.html
	