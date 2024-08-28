all: readme.pdf

%.pdf: %.md
	pandoc -t beamer -s $< -o $@

qr:
	qrencode -o qr.png https://github.com/abbaspour/saml-migration-devday24

.PHONEY: qr