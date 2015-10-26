;+
; NAME: 
;    CALC_NEBULAR
; PURPOSE:
;    Add nebular emission lines to an SED
; EXPLANATION:
;    This takes an input wavelength array, typically of size from Bruzual & Charlot models, 
;    and adds flux associated with nebular emission lines. It requires an input metallicty,
;    and number of ionizing photons (Lyman continuum photons). The output array of emission
;    line flux can be added to the stellar population. The default is for Salpeter IMF
;    models
;    WARNING: NEBULAR CONTINUUM IS NOT YET RELIABLE FOR SCIENCE
; CALLING SEQUENCE:
;    IDL > .com calc_nebular
;    IDL > calc_nebular,lambda,bcflux,n_lyc=45,metallicity=0.02
; INPUTS:
;    lambda - the wavelength array to which you are adding the flux.
;    metallicity - see below for choices
;    n_lyc - log of the number of ionizing photons
; OPTIONAL INPUTS:
;    continuum - set the is flag (/continuum) to add continuum nebular emission
;    f_esc - escape fration of ionizing photons. f_esc=0 means all ionizing photon contribute 
;            to nebular emission. f_esc=1 means no nebular emission
;    nolya - set this flag (/nolya) to exclude Lyman alpha emission
; OUTPUT:
;    bcflux - the output array of the nebular emission flux in units of
;             solar luminosity per Angstrom per BC stellar mass (BC units)
;#############################################################################################
; Using Inoue (2011) relative intensities and emission lines achieved via CLOUDY 08.0
; Citation: Salmon et al. (2015) http://adsabs.harvard.edu/abs/2015ApJ...799..183S
; ############################################################################################
; 10/26/15 Edit: Speed improvements and documentation added
; 3/3/11 Addition: -Chab flag included for Chabrier models
;                  -Lines are in Solar luminosities per Angstrom 
;                  -N_lyc MUST BE A DOUBLE! Otherwise fluxes will be zero.
; -
PRO CALC_NEBULAR, lambda,bcflux,$
                  f_esc=f_esc,$
                  nolya=nolya,$
                  metallicity=metallicity,$
                  N_lyc=N_lyc,$
                  continuum=continuum,$
                  flux_con=flux_con,gam2phot=gam2phot,fbff_ferland=fbff_ferland ; these are not important

if not keyword_set(f_esc) then f_esc=0.0 ; Assume full nebular line emission if not set
if not keyword_set(N_lyc) then N_lyc=0.0 else N_lyc=double(N_lyc) ; Assume no emission lines if not set
if not keyword_set(metallicity) then metallicity=0.008 ; Assume solar metallicity if not set

nebmet = [0.0d, 1.0d-7, 1.0d-5, 4.0d-4, 4.0d-3, 8.0d-3, 2.0d-2]
; These are the BC03 metallicity steps
; Z1 = 0    (POP III)
; Z2 = 1e-7 
; Z3 = 1e-5 
; Z4 = 4e-4 (BC)  0.02
; Z5 = 4e-3 (BC)  0.20
; Z6 = 8e-3 (BC)  0.40
; Z7 = 2e-2 (BC)  1.00

;Rest frame emission line wavelengths
lam_rest=[1216.0d0, 1263.0d0, 1308.0d0, 1335.0d0, 1397.0d0, 1486.0d0, 1531.0d0, 1549.0d0, 1640.0d0, 1665.0d0, $
	  1671.0d0, 1750.0d0, 1786.0d0, 1814.0d0, 1860.0d0, 1888.0d0, 1909.0d0, 2141.0d0, 2326.0d0, 2335.0d0, $
	  2400.0d0, 2471.0d0, 2567.0d0, 2665.0d0, 2798.0d0, 2836.0d0, 2829.0d0, 2829.0d0, 2836.0d0, 2853.0d0, $
	  2945.0d0, 3096.0d0, 3188.0d0, 3203.0d0, 3671.0d0, 3674.0d0, 3676.0d0, 3679.0d0, 3683.0d0, 3687.0d0, $
	  3692.0d0, 3697.0d0, 3704.0d0, 3712.0d0, 3722.0d0, 3722.0d0, 3727.0d0, 3734.0d0, 3750.0d0, 3771.0d0, $
	  3798.0d0, 3820.0d0, 3835.0d0, 3869.0d0, 3889.0d0, 3889.0d0, 3965.0d0, 3968.0d0, 3970.0d0, 4026.0d0, $
	  4070.0d0, 4074.0d0, 4078.0d0, 4102.0d0, 4300.0d0, 4340.0d0, 4363.0d0, 4471.0d0, 4659.0d0, 4686.0d0, $
	  4702.0d0, 4755.0d0, 4770.0d0, 4861.0d0, 4881.0d0, 4922.0d0, 4959.0d0, 5007.0d0, 5012.0d0, 5016.0d0, $
	  5199.0d0, 5271.0d0, 5755.0d0, 5828.0d0, 5876.0d0, 6300.0d0, 6312.0d0, 6363.0d0, 6548.0d0, 6563.0d0, $
	  6584.0d0, 6678.0d0, 6716.0d0, 6720.0d0, 6731.0d0, 7065.0d0, 7135.0d0, 7325.0d0, 7751.0d0, 8334.0d0, $
	  8346.0d0, 8359.0d0, 8374.0d0, 8392.0d0, 8413.0d0, 8438.0d0, 8467.0d0, 8502.0d0, 8545.0d0, 8598.0d0, $
	  8617.0d0, 8665.0d0, 8750.0d0, 8863.0d0, 9015.0d0, 9069.0d0, 9229.0d0, 9532.0d0, 9546.0d0,  $
          18746.1d0, 12814.7d0, 10935.2d0, 10046.7d0, $ ; Extra Paschen Lines, n'= 4 - 7
          40500.8d0, 26244.5d0, 21649.5d0, 19440.4d0, 18169.3d0, 17357.5d0 ] ; Extra Bracket lines, n'= 5 - 10
;Intensities relative to H_beta. stdvZ = standard deviation of average intensities
allZ = dblarr(n_elements(nebmet),n_elements(lam_rest))
allstdv = dblarr(n_elements(nebmet),n_elements(lam_rest))
allZ[0,*] = double([39.360001, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.078070, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.008346, 0.000000, 0.000000, $
		0.014990, 0.000000, 0.030920, 0.003812, 0.002892, 0.003279, 0.003741, 0.004297, 0.004972, 0.005797, $
		0.006817, 0.008095, 0.009717, 0.011800, 0.014540, 0.000000, 0.000000, 0.018190, 0.023180, 0.030200, $
		0.050650, 0.007635, 0.070250, 0.000000, 0.073950, 0.101100, 0.007226, 0.000000, 0.154400, 0.013840, $
		0.000000, 0.000000, 0.000000, 0.255100, 0.000000, 0.472100, 0.000000, 0.028730, 0.000000, 0.009598, $
		0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.007698, 0.000000, 0.000000, 0.000000, 0.017570, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.075110, 0.000000, 0.000000, 0.000000, 0.000000, 2.990000, $
		0.000000, 0.020900, 0.000000, 0.000000, 0.000000, 0.020110, 0.000000, 0.000000, 0.000000, 0.000931, $
		0.001057, 0.001207, 0.001387, 0.001605, 0.001872, 0.002201, 0.002613, 0.003136, 0.003807, 0.004685, $
		0.000000, 0.005859, 0.007460, 0.009707, 0.016040, 0.000000, 0.022240, 0.000000, 0.032080, 0.3386, $
		0.1632, 0.09044, 0.05546, 0.08021, 0.04547, 0.02781, 0.01826, 0.01266, 0.009142]) 
allZ[1,*] = double([37.209999, 0.000090, 0.000008, 0.000063, 0.000193, 0.000042, 0.000011, 0.001726, 0.020730, 0.000071, $
		0.000016, 0.000009, 0.000055, 0.000002, 0.000003, 0.000045, 0.000152, 0.000000, 0.000004, 0.000002, $
		0.000022, 0.000001, 0.000006, 0.000003, 0.000068, 0.000018, 0.000010, 0.011870, 0.000018, 0.000001, $
		0.021280, 0.000014, 0.043810, 0.000662, 0.002982, 0.003382, 0.003858, 0.004432, 0.005127, 0.005978, $
		0.007030, 0.008348, 0.010020, 0.012170, 0.014990, 0.000001, 0.000030, 0.018760, 0.023910, 0.031150, $
		0.051580, 0.010910, 0.071470, 0.000042, 0.104500, 0.102400, 0.010420, 0.000013, 0.156100, 0.019780, $
		0.000001, 0.000001, 0.000000, 0.257100, 0.000002, 0.473200, 0.000017, 0.041070, 0.000001, 0.001741, $
		0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.011000, 0.000128, 0.000384, 0.000000, 0.025310, $
		0.000000, 0.000001, 0.000000, 0.000000, 0.107500, 0.000001, 0.000001, 0.000000, 0.000002, 2.961000, $
		0.000005, 0.029890, 0.000004, 0.000007, 0.000003, 0.029470, 0.000002, 0.000001, 0.000000, 0.000959, $
		0.001089, 0.001244, 0.001429, 0.001654, 0.001929, 0.002268, 0.002693, 0.003231, 0.003923, 0.004828, $
		0.000000, 0.006037, 0.007687, 0.010000, 0.016240, 0.000006, 0.022490, 0.000014, 0.032350, 0.3386, $
		0.1632, 0.09044, 0.05546, 0.08021, 0.04547, 0.02781, 0.01826, 0.01266, 0.009142])
allZ[2,*] = double([35.000000, 0.003793, 0.000843, 0.003114, 0.008998, 0.003615, 0.001005, 0.055310, 0.009225, 0.006652, $
		0.001471, 0.001062, 0.001960, 0.000395, 0.000403, 0.005181, 0.016990, 0.000042, 0.000459, 0.000196, $
		0.001784, 0.000081, 0.000538, 0.000309, 0.004295, 0.001750, 0.000997, 0.011980, 0.001750, 0.000071, $
		0.021480, 0.001373, 0.044220, 0.000189, 0.003077, 0.003489, 0.003981, 0.004573, 0.005290, 0.006168, $
		0.007254, 0.008614, 0.010340, 0.012560, 0.015470, 0.000071, 0.003189, 0.019360, 0.024670, 0.032140, $
		0.052820, 0.011040, 0.073290, 0.004143, 0.105500, 0.104500, 0.010590, 0.001249, 0.158800, 0.020020, $
		0.000054, 0.000072, 0.000018, 0.260600, 0.000826, 0.475900, 0.001614, 0.041570, 0.000160, 0.000574, $
		0.000048, 0.000029, 0.000016, 1.000000, 0.000023, 0.011140, 0.012560, 0.037800, 0.000017, 0.025650, $
		0.000017, 0.000079, 0.000015, 0.000031, 0.108900, 0.000064, 0.000121, 0.000020, 0.000185, 2.926000, $
		0.000546, 0.030290, 0.000397, 0.000684, 0.000286, 0.029710, 0.000216, 0.000109, 0.000052, 0.000989, $
		0.001123, 0.001283, 0.001474, 0.001706, 0.001989, 0.002340, 0.002777, 0.003332, 0.004046, 0.004980, $
		0.000016, 0.006226, 0.007928, 0.010320, 0.016430, 0.000639, 0.022760, 0.001586, 0.032630, 0.3386, $
		0.1632, 0.09044, 0.05546, 0.08021, 0.04547, 0.02781, 0.01826, 0.01266, 0.009142])
allZ[3,*] = double([29.719999, 0.014370, 0.008145, 0.024170, 0.105100, 0.046200, 0.008126, 0.570400, 0.008799, 0.135000, $
		0.011910, 0.041050, 0.005741, 0.007310, 0.014200, 0.216400, 0.541300, 0.002005, 0.023140, 0.006676, $
		0.020140, 0.004113, 0.015010, 0.014180, 0.100100, 0.049620, 0.028440, 0.012540, 0.049620, 0.002489, $
		0.022460, 0.040380, 0.046200, 0.000048, 0.003604, 0.004087, 0.004662, 0.005355, 0.006195, 0.007222, $
		0.008493, 0.010080, 0.012100, 0.014700, 0.018110, 0.003152, 0.164200, 0.022650, 0.028870, 0.037600, $
		0.055860, 0.011850, 0.075830, 0.129900, 0.111000, 0.107500, 0.011350, 0.039140, 0.162300, 0.021480, $
		0.002187, 0.002901, 0.000714, 0.264600, 0.005218, 0.476900, 0.040770, 0.044680, 0.008424, 0.000165, $
		0.002509, 0.001541, 0.000841, 1.000000, 0.001197, 0.012000, 0.406700, 1.224000, 0.000915, 0.027270, $
		0.000499, 0.004172, 0.000727, 0.001561, 0.117400, 0.001748, 0.005342, 0.000558, 0.008784, 2.881000, $
		0.025920, 0.032790, 0.015890, 0.027370, 0.011490, 0.030890, 0.010130, 0.005535, 0.002444, 0.001165, $
		0.001322, 0.001510, 0.001735, 0.002008, 0.002342, 0.002754, 0.003269, 0.003922, 0.004762, 0.005861, $
		0.000492, 0.007328, 0.009331, 0.012140, 0.017340, 0.030230, 0.023730, 0.074980, 0.033860, 0.3386, $
		0.1632, 0.09044, 0.05546, 0.08021, 0.04547, 0.02781, 0.01826, 0.01266, 0.009142])
allZ[4,*] = double([25.090000, 0.025380, 0.012190, 0.049410, 0.089680, 0.017480, 0.011880, 0.272000, 0.036120, 0.098590, $
		0.016690, 0.047300, 0.011620, 0.025640, 0.025510, 0.305500, 0.688500, 0.008210, 0.089920, 0.030680, $
		0.120900, 0.017700, 0.029610, 0.042380, 0.479900, 0.104800, 0.061270, 0.012030, 0.104800, 0.007880, $
		0.021480, 0.100000, 0.044250, 0.001826, 0.003792, 0.004296, 0.004897, 0.005620, 0.006496, 0.007569, $
		0.008894, 0.010550, 0.012650, 0.015360, 0.018900, 0.011500, 0.961500, 0.023630, 0.030090, 0.039160, $
		0.057220, 0.012610, 0.077500, 0.421400, 0.108500, 0.109300, 0.011280, 0.127000, 0.164300, 0.022930, $
		0.013650, 0.018120, 0.004465, 0.266400, 0.048590, 0.475800, 0.059750, 0.048290, 0.050620, 0.004867, $
		0.014980, 0.009258, 0.005020, 1.000000, 0.007419, 0.013080, 1.493000, 4.494000, 0.005595, 0.027190, $
		0.003898, 0.026290, 0.004101, 0.010310, 0.130900, 0.013520, 0.019500, 0.004312, 0.070580, 2.883000, $
		0.208300, 0.036990, 0.120500, 0.207000, 0.086540, 0.028610, 0.061660, 0.024160, 0.014880, 0.001276, $
		0.001448, 0.001653, 0.001898, 0.002196, 0.002560, 0.003009, 0.003571, 0.004283, 0.005198, 0.006396, $
		0.004756, 0.007996, 0.010180, 0.013250, 0.018440, 0.193000, 0.025220, 0.478800, 0.035930, 0.3386, $
		0.1632, 0.09044, 0.05546, 0.08021, 0.04547, 0.02781, 0.01826, 0.01266, 0.009142])
allZ[5,*] = double([24.209999, 0.034480, 0.012770, 0.067000, 0.062600, 0.002909, 0.011810, 0.075950, 0.056070, 0.025630, $
		0.016020, 0.014940, 0.013460, 0.019410, 0.020590, 0.115500, 0.257000, 0.005651, 0.068780, 0.026630, $
		0.123800, 0.013100, 0.014950, 0.027210, 0.411200, 0.055880, 0.033220, 0.011400, 0.055880, 0.006169, $
		0.020330, 0.060290, 0.041930, 0.003075, 0.003828, 0.004334, 0.004937, 0.005662, 0.006541, 0.007617, $
		0.008944, 0.010610, 0.012710, 0.015420, 0.018960, 0.009805, 0.984900, 0.023690, 0.030140, 0.039200, $
		0.056870, 0.012770, 0.077030, 0.325100, 0.104100, 0.108600, 0.010970, 0.097990, 0.163300, 0.023310, $
		0.015380, 0.020410, 0.005034, 0.264900, 0.074990, 0.473100, 0.025100, 0.049640, 0.054380, 0.008525, $
		0.015980, 0.009944, 0.005355, 1.000000, 0.008234, 0.013500, 1.289000, 3.880000, 0.006122, 0.026530, $
		0.005124, 0.029710, 0.003934, 0.012330, 0.138600, 0.017440, 0.016620, 0.005561, 0.101400, 2.929000, $
		0.299200, 0.039360, 0.169500, 0.290500, 0.121000, 0.026800, 0.074840, 0.018540, 0.018060, 0.001324, $
		0.001501, 0.001713, 0.001967, 0.002274, 0.002650, 0.003114, 0.003694, 0.004429, 0.005375, 0.006611, $
		0.008186, 0.008264, 0.010520, 0.013690, 0.018920, 0.271600, 0.025910, 0.673600, 0.036950, 0.3386, $
		0.1632, 0.09044, 0.05546, 0.08021, 0.04547, 0.02781, 0.01826, 0.01266, 0.009142])
allZ[6,*] = double([24.490000, 0.070010, 0.016580, 0.124300, 0.068700, 0.000038, 0.014930, 0.035170, 0.032970, 0.000687, $
		0.026970, 0.000150, 0.015290, 0.006514, 0.022740, 0.005033, 0.002861, 0.000556, 0.008968, 0.002615, $
		0.018130, 0.001922, 0.000339, 0.002664, 0.063980, 0.001498, 0.000940, 0.009602, 0.001498, 0.002937, $
		0.017120, 0.002096, 0.035370, 0.001835, 0.003881, 0.004384, 0.004984, 0.005704, 0.006578, 0.007645, $
		0.008961, 0.010610, 0.012690, 0.015370, 0.018860, 0.001664, 0.374400, 0.023520, 0.029870, 0.038770, $
		0.055030, 0.012360, 0.074680, 0.026650, 0.090150, 0.105400, 0.009745, 0.008032, 0.158800, 0.022830, $
		0.004684, 0.006222, 0.001538, 0.258200, 0.026500, 0.464300, 0.000385, 0.050130, 0.023660, 0.005801, $
		0.006819, 0.004327, 0.002286, 1.000000, 0.003944, 0.013730, 0.170100, 0.512000, 0.002811, 0.024060, $
		0.001278, 0.014980, 0.001125, 0.006233, 0.152700, 0.004104, 0.002821, 0.001309, 0.090310, 3.093000, $
		0.266500, 0.043680, 0.115300, 0.197100, 0.081870, 0.022500, 0.034130, 0.004406, 0.008236, 0.001424, $
		0.001612, 0.001836, 0.002106, 0.002431, 0.002830, 0.003321, 0.003936, 0.004714, 0.005719, 0.007027, $
		0.006137, 0.008780, 0.011170, 0.014540, 0.019780, 0.210800, 0.027180, 0.522900, 0.038970, 0.3386, $
		0.1632, 0.09044, 0.05546, 0.08021, 0.04547, 0.02781, 0.01826, 0.01266, 0.009142])
; ############################################################################################################################
allstdv[0,*] = double([0.474400, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.014480, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000046, 0.000000, 0.000000, $
		0.000092, 0.000000, 0.000237, 0.000797, 0.000110, 0.000124, 0.000142, 0.000163, 0.000188, 0.000219, $
		0.000258, 0.000306, 0.000367, 0.000445, 0.000548, 0.000000, 0.000000, 0.000685, 0.000873, 0.001137, $
		0.000092, 0.000079, 0.000117, 0.000000, 0.000785, 0.000134, 0.000044, 0.000000, 0.000159, 0.000142, $
		0.000000, 0.000000, 0.000000, 0.000186, 0.000000, 0.000207, 0.000000, 0.000310, 0.000000, 0.001999, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000090, 0.000000, 0.000000, 0.000000, 0.000110, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000919, 0.000000, 0.000000, 0.000000, 0.000000, 0.005336, $
		0.000000, 0.000281, 0.000000, 0.000000, 0.000000, 0.000625, 0.000000, 0.000000, 0.000000, 0.000036, $
		0.000041, 0.000047, 0.000054, 0.000063, 0.000073, 0.000086, 0.000102, 0.000122, 0.000149, 0.000183, $
		0.000000, 0.000229, 0.000291, 0.000379, 0.000072, 0.000000, 0.000096, 0.000000, 0.000135, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000])
allstdv[1,*] = double([0.441600, 0.000021, 0.000002, 0.000019, 0.000026, 0.000007, 0.000003, 0.000322, 0.001741, 0.000009, $
		0.000003, 0.000000, 0.000016, 0.000000, 0.000000, 0.000003, 0.000009, 0.000000, 0.000000, 0.000000, $
		0.000005, 0.000000, 0.000001, 0.000000, 0.000011, 0.000002, 0.000001, 0.000053, 0.000002, 0.000000, $
		0.000123, 0.000001, 0.000370, 0.000027, 0.000105, 0.000119, 0.000135, 0.000155, 0.000180, 0.000209, $
		0.000246, 0.000292, 0.000351, 0.000425, 0.000524, 0.000000, 0.000004, 0.000655, 0.000834, 0.001086, $
		0.000099, 0.000099, 0.000129, 0.000003, 0.001298, 0.000146, 0.000036, 0.000001, 0.000174, 0.000175, $
		0.000000, 0.000000, 0.000000, 0.000201, 0.000000, 0.000232, 0.000002, 0.000385, 0.000000, 0.000086, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000114, 0.000009, 0.000027, 0.000000, 0.000101, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.001169, 0.000000, 0.000000, 0.000000, 0.000000, 0.005790, $
		0.000001, 0.000366, 0.000001, 0.000001, 0.000000, 0.001067, 0.000000, 0.000000, 0.000000, 0.000035, $
		0.000040, 0.000045, 0.000052, 0.000060, 0.000070, 0.000083, 0.000098, 0.000118, 0.000143, 0.000176, $
		0.000000, 0.000219, 0.000279, 0.000364, 0.000074, 0.000000, 0.000099, 0.000001, 0.000141, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000])
allstdv[2,*] = double([0.428600, 0.000344, 0.000161, 0.000287, 0.000952, 0.000635, 0.000167, 0.009813, 0.001253, 0.000869, $
		0.000179, 0.000056, 0.000298, 0.000066, 0.000027, 0.000298, 0.001124, 0.000005, 0.000043, 0.000015, $
		0.000295, 0.000010, 0.000052, 0.000030, 0.000238, 0.000165, 0.000093, 0.000068, 0.000165, 0.000005, $
		0.000152, 0.000131, 0.000434, 0.000020, 0.000096, 0.000108, 0.000124, 0.000142, 0.000164, 0.000191, $
		0.000225, 0.000266, 0.000320, 0.000388, 0.000477, 0.000003, 0.000441, 0.000597, 0.000760, 0.000989, $
		0.000099, 0.000101, 0.000183, 0.000282, 0.001448, 0.000210, 0.000040, 0.000085, 0.000332, 0.000178, $
		0.000007, 0.000009, 0.000002, 0.000593, 0.000247, 0.000775, 0.000172, 0.000386, 0.000019, 0.000065, $
		0.000006, 0.000003, 0.000002, 0.000000, 0.000003, 0.000116, 0.000874, 0.002630, 0.000002, 0.000110, $
		0.000002, 0.000009, 0.000002, 0.000004, 0.001147, 0.000009, 0.000004, 0.000003, 0.000027, 0.008229, $
		0.000080, 0.000367, 0.000052, 0.000090, 0.000038, 0.001045, 0.000011, 0.000014, 0.000003, 0.000032, $
		0.000037, 0.000042, 0.000048, 0.000056, 0.000065, 0.000076, 0.000090, 0.000108, 0.000131, 0.000162, $
		0.000002, 0.000202, 0.000257, 0.000335, 0.000073, 0.000034, 0.000095, 0.000083, 0.000139, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000])
allstdv[3,*] = double([0.320100, 0.000776, 0.000482, 0.001015, 0.012070, 0.008782, 0.000443, 0.112800, 0.001061, 0.014650, $
		0.000551, 0.002562, 0.000315, 0.000345, 0.000899, 0.011350, 0.035680, 0.000249, 0.002134, 0.000473, $
		0.002439, 0.000515, 0.001363, 0.001223, 0.009192, 0.004402, 0.002515, 0.000046, 0.004402, 0.000180, $
		0.000099, 0.003664, 0.000315, 0.000001, 0.000002, 0.000003, 0.000003, 0.000003, 0.000004, 0.000004, $
		0.000005, 0.000006, 0.000007, 0.000009, 0.000011, 0.000110, 0.022140, 0.000014, 0.000019, 0.000025, $
		0.000144, 0.000030, 0.000157, 0.007777, 0.001145, 0.000167, 0.000027, 0.002344, 0.000217, 0.000057, $
		0.000279, 0.000370, 0.000091, 0.000318, 0.000769, 0.000323, 0.003681, 0.000149, 0.000909, 0.000007, $
		0.000270, 0.000166, 0.000091, 0.000000, 0.000131, 0.000045, 0.026010, 0.078290, 0.000099, 0.000050, $
		0.000083, 0.000457, 0.000097, 0.000170, 0.000619, 0.000257, 0.000187, 0.000082, 0.001273, 0.005034, $
		0.003757, 0.000181, 0.002137, 0.003678, 0.001541, 0.001259, 0.000372, 0.000681, 0.000090, 0.000003, $
		0.000004, 0.000004, 0.000005, 0.000005, 0.000006, 0.000007, 0.000009, 0.000010, 0.000012, 0.000015, $
		0.000074, 0.000019, 0.000024, 0.000031, 0.000034, 0.001292, 0.000047, 0.003204, 0.000070, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000])
allstdv[4,*] = double([0.113400, 0.001222, 0.000613, 0.001420, 0.009421, 0.003407, 0.000516, 0.049950, 0.001985, 0.007865, $
		0.000700, 0.002401, 0.000571, 0.001840, 0.001044, 0.013290, 0.028950, 0.001037, 0.009936, 0.003020, $
		0.016290, 0.002261, 0.002274, 0.004131, 0.049640, 0.007800, 0.004573, 0.000040, 0.007800, 0.000747, $
		0.000121, 0.007754, 0.000414, 0.000117, 0.000002, 0.000002, 0.000003, 0.000003, 0.000004, 0.000004, $
		0.000005, 0.000006, 0.000008, 0.000009, 0.000012, 0.000574, 0.129400, 0.000015, 0.000019, 0.000025, $
		0.000134, 0.000015, 0.000150, 0.015550, 0.001474, 0.000144, 0.000017, 0.004687, 0.000169, 0.000028, $
		0.001804, 0.002394, 0.000590, 0.000238, 0.007093, 0.000249, 0.003888, 0.000070, 0.005633, 0.000310, $
		0.001665, 0.001030, 0.000558, 0.000000, 0.000832, 0.000019, 0.071600, 0.215500, 0.000625, 0.000037, $
		0.000636, 0.002955, 0.000549, 0.001107, 0.000288, 0.001927, 0.000972, 0.000615, 0.010220, 0.001658, $
		0.030170, 0.000074, 0.016600, 0.028500, 0.011900, 0.001210, 0.002416, 0.002981, 0.000583, 0.000001, $
		0.000001, 0.000001, 0.000001, 0.000002, 0.000002, 0.000002, 0.000003, 0.000003, 0.000004, 0.000005, $
		0.000723, 0.000006, 0.000007, 0.000010, 0.000022, 0.010870, 0.000026, 0.026970, 0.000030, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000])
allstdv[5,*] = double([0.069180, 0.001760, 0.000651, 0.001346, 0.006844, 0.000524, 0.000556, 0.009656, 0.003356, 0.002342, $
		0.000815, 0.001062, 0.000641, 0.001056, 0.000963, 0.004909, 0.014660, 0.000619, 0.007016, 0.002479, $
		0.015470, 0.001512, 0.001288, 0.002513, 0.040110, 0.004619, 0.002757, 0.000042, 0.004619, 0.000486, $
		0.000127, 0.004944, 0.000435, 0.000200, 0.000003, 0.000003, 0.000003, 0.000004, 0.000004, 0.000005, $
		0.000006, 0.000007, 0.000009, 0.000011, 0.000014, 0.000403, 0.123200, 0.000017, 0.000022, 0.000029, $
		0.000131, 0.000017, 0.000151, 0.012150, 0.001555, 0.000140, 0.000023, 0.003663, 0.000157, 0.000030, $
		0.001985, 0.002635, 0.000650, 0.000204, 0.010610, 0.000219, 0.001799, 0.000067, 0.005643, 0.000556, $
		0.001655, 0.001032, 0.000555, 0.000000, 0.000864, 0.000015, 0.065290, 0.196500, 0.000638, 0.000044, $
		0.000805, 0.003124, 0.000476, 0.001221, 0.000203, 0.002391, 0.000682, 0.000762, 0.014020, 0.001044, $
		0.041390, 0.000040, 0.023090, 0.039550, 0.016470, 0.001221, 0.002608, 0.001967, 0.000630, 0.000001, $
		0.000001, 0.000001, 0.000001, 0.000001, 0.000002, 0.000002, 0.000002, 0.000003, 0.000003, 0.000004, $
		0.001245, 0.000005, 0.000007, 0.000009, 0.000020, 0.012990, 0.000024, 0.032220, 0.000025, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000])
allstdv[6,*] = double([0.065270, 0.003742, 0.000954, 0.003783, 0.011060, 0.000009, 0.000841, 0.005595, 0.003073, 0.000111, $
		0.001532, 0.000035, 0.000853, 0.000295, 0.002028, 0.000506, 0.000711, 0.000036, 0.000525, 0.000267, $
		0.001527, 0.000140, 0.000099, 0.000250, 0.005518, 0.000402, 0.000250, 0.000058, 0.000402, 0.000184, $
		0.000140, 0.000449, 0.000449, 0.000173, 0.000002, 0.000003, 0.000003, 0.000004, 0.000005, 0.000006, $
		0.000007, 0.000009, 0.000011, 0.000014, 0.000018, 0.000113, 0.027840, 0.000023, 0.000030, 0.000041, $
		0.000183, 0.000057, 0.000202, 0.003404, 0.001608, 0.000194, 0.000056, 0.001026, 0.000232, 0.000104, $
		0.000646, 0.000858, 0.000212, 0.000291, 0.003744, 0.000257, 0.000097, 0.000221, 0.001697, 0.000524, $
		0.000489, 0.000310, 0.000164, 0.000000, 0.000295, 0.000058, 0.021470, 0.064620, 0.000204, 0.000120, $
		0.000227, 0.001100, 0.000067, 0.000447, 0.000642, 0.000730, 0.000192, 0.000233, 0.008576, 0.003207, $
		0.025310, 0.000174, 0.015940, 0.027330, 0.011400, 0.001266, 0.001955, 0.000169, 0.000472, 0.000001, $
		0.000001, 0.000001, 0.000002, 0.000002, 0.000002, 0.000002, 0.000003, 0.000003, 0.000004, 0.000004, $
		0.000926, 0.000006, 0.000007, 0.000009, 0.000037, 0.008413, 0.000045, 0.020860, 0.000054, 0.000000, $
		0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000])

;; Assign the metallicity of the nebular gas
if metallicity lt 0 then begin
   print, "% WARNING", "% Metallcity below 0.0",$
        "% Please choose one of these metallicities: 0, 1e-7, 1e-5, 4e-4, 4e-3, 8e-3, 2e-2"
   return
endif else if metallicity gt max(metallicity) then begin
   print, "% WARNING", "% Metallicity greater than maximum provided by BC03",$
        "% Please choose one of these metallicities: 0, 1e-7, 1e-5, 4e-4, 4e-3, 8e-3, 2e-2"
   return
endif else Z = reform(allZ[findel(metallicity,nebmet),*])

;; If keyword set, turn off Lyman Alpha emission line
if keyword_set(nolya) then begin
   lam_rest=lam_rest[1:(n_elements(lam_rest)-1)]
   Z=Z[1:(n_elements(Z)-1)]
endif

;Compute emission line fluxes
flux=dblarr(n_elements(lam_rest))
for i=0,n_elements(lam_rest)-1 do flux(i)= 4.78d-13*(10.0d0^N_lyc)*(1.0d0-f_esc)*Z(i)*(1.0d0/3.839d33)$
                                                                   /(1+0.6d*f_esc)  ; Inoue (2011) includes this term
;Compute dlambda
bcflux=lambda*0.0d0 & dlam=lambda ;Define BC03-resolution flux array & dlambda array
dlam(0)=lambda(1)-lambda(0) & dlam(n_elements(lambda)-1)=lambda(n_elements(lambda)-1)-lambda(n_elements(lambda)-2)
for i=1,n_elements(lambda)-2 do dlam(i)=mean([(lambda(i)-lambda(i-1)),(lambda(i+1)-lambda(i))])

;Compute emission line spectrum (in flux density units)
for i=0,n_elements(lam_rest)-1 do bcflux[findel(lam_rest(i),lambda)]=bcflux[findel(lam_rest(i),lambda)]+ (flux(i)/dlam[findel(lam_rest(i),lambda)])

;Continuum
if keyword_set(continuum) then begin
  print, "% WARNING"
  print, "% Dust continuum is not ready for science."
  print, "% There's some factor unaccounted for in the 2-photon continuum emission."
  ;Free-Free and Free-Bound emission
  lam_ferland=(6.626069d-27*2.9979d18)/2.17987d-11/[1.0,0.25, 0.25,0.111,0.111,.0625,$
       .0625,.04,.04,.0278,.0278,.0204,.0204,.0156,.0156,.0123,.0123,.01,.01,.0083,.0083,.0069]
  fbff_ferland=1d-40/lam_ferland*2.9979d18*[2.11d-4,2.48d1,1.37,1.15d1,4.26,9.04,5.93,$
       8.51,6.9,8.5,7.56,8.66,8.06,8.87,8.47,9.11,8.82,9.34,9.14,9.58,9.42,9.8]
  aa = dindgen(50)*20.d +20.d & bb= (dindgen(19800)*5.d +1005.d) & cc= (dindgen(11997)*30000.d +120000.d)
  lam = [aa, bb, cc] ; Create new wavelength spacing so calculate continuum at high resolution only in key areas
  fbff_ferland=lam/2.9979d18*10.d^(interpol(alog10(fbff_ferland),alog10(lam_ferland),alog10(lam))) ; fb&ff emission coefficients in erg cm^3/s/Hz

  ;2 Photon Emission
  y=2.9979d18/lam/2.4661d15 ;frequency normalized to Lyman_a frequency
  C = 202.d & B = 1.53d & G = 0.8d & alpha = 0.88d
  A = C*[ y*(1-y)*(1-(4.d*y*(1-y))^G)$
     +alpha*(y*(1-y))^B*(4.d*y*(1-y))^G ] ; A(y) from Naussbaumer & Schmutz 1984
  foo= where( A gt 1d-100 and A lt 1d100, complement=nan) & A(nan)=1d-60 ; set nonreal values to zero
  gam2phot= 2.9979d18/lam*2*6.626069d-27*y*A*0.32d*2.59d-13*lam/2.9979d18 $; Inoue 2010, gamma_twophoton in erg cm^3/s/Hz
          /16.1d ; for some reason I need this correction factor.. this is why continuum is not yet reliable
  g_tot= double(gam2phot+fbff_ferland)*2.9979d18/(lam^2.d0) ; total continuum coefficient gamma
  flux_con= g_tot*(10.0d0^N_lyc)*(1.0d0/3.839d33)*(1.0d0-f_esc)/(2.59d-13 + 1.58d-13*f_esc) ; Calculate appropriate line strength in BC flux units [L_sol/A/M_sol]

  ;; Now make flux array in units L_sol/Angstrom/M_sol and of the same wavelength steps as lambda
  BCnebcon = interpol(flux_con, lam, lambda) ; BCnebcon is Nebular Continuum put into BClam spacing
  BCnebcon[0:findel(lambda,1205)]=1d-60 ; Destroy flux shortward of 1215 A, it's a relic of poor interpolation
  bcflux = BCnebcon + bcflux ; Add nebular continuum and lines together! :)
endif

END
