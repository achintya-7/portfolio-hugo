server:
	hugo server -D

paper:
	git clone https://github.com/adityatelange/hugo-PaperMod themes/PaperMod --depth=1
 
.PHONY: server paper