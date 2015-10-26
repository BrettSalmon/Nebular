# calc_nebular.pro
This is an IDL procedure to add nebular emission lines 
to stellar population synthesis models. It takes an 
input wavelength array, typically of size from 
Bruzual & Charlot models, and adds flux associated 
with nebular emission lines. It requires an input 
metallicty, and number of ionizing photons (Lyman 
continuum photons). The output array of emission 
line flux can be added to the stellar population. 
Further documentation on its use and calling sequence
can be found in the header. 

If you use this procedure, please cite the following paper:
Salmon et al. (2015) http://adsabs.harvard.edu/abs/2015ApJ...799..183S

If you have any questions, comments, or concerns, 
feel free to contact me at bsalmon@physics.tamu.edu

