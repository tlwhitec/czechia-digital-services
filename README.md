# czechia-digital-services
Nástroje pro práci s datovými formáty veřejných českých služeb.

Tools for operating with various Czech public services data formats.

## Extrakce datových zpráv z [datové schránky](https://www.mojedatovaschranka.cz/)
`extract-zfo <datova-zprava.zfo>`

Vytvoří adresář vedle `<datova-zprava.zfo>`, ověří podpis vstupního souboru a extrahuje do něj přiloženou přílohu.

## Extrakce příloh z potvrzení (či pracovního souboru) [elektronických podání pro finanční správu](https://adisepo.mfcr.cz/adistc/adis/idpr_epo/epo2/uvod/vstup.faces)
`extract-epo [<soubor.p7s> | <soubor.xml>]`

Vytvoří adresář vedle vstupního souboru a extrahuje do něj všechny přílohy. Pokud byl použit soubor s podpisem formátu `p7s`, je tento předem ověřen a dekódován.
