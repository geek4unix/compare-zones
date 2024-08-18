# compare-zones

This script was made to compare two zone files during a migration.

It uses colour coding and a final status output to indicate what records are different 

SOA and NS records will be different during a migration - just note the differences

ANY record will probably be different too as it includes above types in it.
A, AAAA, CNAME. MX and TXT records should be the same , if they exist - difference here means a problem !

See Example Screenshot

![Example Image](image.png?raw=true)
