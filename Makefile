all: readme.pdf

%.png: %.dot
	dot -Tpng -Gdpi=100 -o $@ $<
%.pdf: %.md
	pandoc -t beamer -s $< -o $@

qr:
	qrencode -o qr.png https://github.com/abbaspour/saml-migration-devday24

%.png: %.dot
	dot -Tpng -Gdpi=100 -o $@ $<

.PHONEY: qr