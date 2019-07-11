** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name			        salt_fa_001.do
    //  project:				        Health of the Nation (HotN)
    //  analysts:				       	Ian HAMBLETON
    // 	date last modified	            09-MAY-2019
    //  algorithm task			        Reading the SALT dataset. Initial preparation. Initial Factor Analysis.

    ** General algorithm set-up
    version 15
    clear all
    macro drop _all
    set more 1
    set linesize 80

    ** Set working directories: this is for DATASET and LOGFILE import and export
    ** DATASETS to encrypted SharePoint folder
    local datapath "X:/The University of the West Indies/DataGroup - repo_data/data_p128"
    ** LOGFILES to unencrypted OneDrive folder (.gitignore set to IGNORE log files on PUSH to GitHub)
    local logpath X:/OneDrive - The University of the West Indies/repo_datagroup/repo_p128

    ** Close any open log file and open a new log file
    capture log close
    log using "`logpath'\salt_fa_001", replace
** HEADER -----------------------------------------------------



** ------------------------------------------------------------
** FILE 1 - DATA PREPARATION
** ------------------------------------------------------------
use "`datapath'/version01/2-working/pca_30.dta" ,clear

** Rename to shorten the food weight variables
rename grams* g*

** Calorie distributions 
** Removing unlikely outliers 


** Data Sparseness, and variable correlations
** A possible case for reducing the number of food groups?
** For Discussion...

** Proportion of empty categories
** 1 = Not eaten during data collection period
preserve 
    forval x = 1(1)30 {
        gen empty`x' = 0
        replace empty`x'=1 if g`x'==0
    }
    keep pid empty* 
   reshape long empty , i(pid) j(group) 
    collapse (sum) empty, by(group)
    ** N=364 participants
    gen percent_empty = (empty/364)*100
    sort percent_empty 
    gen group_order = _n
    sdecode group , gen(group_string)
    labmask group_order, values(group_string)
    drop group_string 
    tabdisp group_order, cell(percent_empty) format(%9.1f)
restore 


** Initialize  macros
global xlist g1 g2 g3 g4 g5 g6 g7 g8 g9 g10 g11 g12 g13 g14 g15 g16 g17 g18 g19 g20 g21 g22 g23 g24 g25 g26 g27 g28 g29 g30
global id pid 
global ncomp 3 

** Describe food categories
des  $xlist 
sum  $xlist 
corr $xlist 

** Correlations between food categories
** Small correlations reduce the usefulness of the FA / PCA process 
** An indication that food groupings could be reduced / improved 
preserve
    matrix CORR = r(C) 
    mata: a=st_matrix("CORR")
    mata: LCORR=vech(a)
    mata: st_matrix("CORR", LCORR)
    svmat CORR
    keep CORR 
    drop if CORR == 1 
    gen ind = _n

    ** Plot the correlations --> INDEX PLOT
    ** To visually show the correlation sizes 
    #delimit ;
	gr twoway
		/// Correlation
		(sc CORR ind , msize(3.5) m(o) mlc(gs0) mfc("161 217 155 %75") mlw(0.1))
		,
			graphregion(color(gs16)) 
            ysize(5) xsize(10)

			xlab(0(100)400 , labs(3) tlc(gs0) labc(gs0) nogrid glc(gs16))
			xscale(fill lc(gs0))
			xtitle("Correlations", size(3) color(gs0) margin(l=2 r=2 t=5 b=2))
			xmtick(0(50)450, tlc(gs0))

			ylab(-0.4(0.1)0.5
			,
			valuelabel labc(gs0) labs(3) tstyle(major_notick) nogrid glc(gs16) angle(0) format(%9.2f))
			yscale(noline lw(vthin) )
			ytitle("", size(3) margin(l=2 r=5 t=2 b=2))

            yline(0, lc(gs2 ) lp("-"))

			legend(off size(3) position(12) ring(1) bm(t=1 b=4 l=5 r=0) colf cols(1)
			region(fcolor(gs16) lw(vthin) margin(l=2 r=2 t=2 b=2))
			order(2 3 4)
			lab(2 "Min 30q70")
			lab(3 "Max 30q70")
			lab(4 "Regional 30q70")
            )
            name(corelations)
            ;
    #delimit cr
restore

** Scree plot of the eigenvalues 
qui pca $xlist 
#delimit ; 
screeplot , 
	graphregion(color(gs16)) 
    yline(1.5, lc(gs2 ) lp("-")) 
    yline(1.0,  lc(gs2 ) lp("-")) 
    text(1.6 21 "17% variance explained", color(gs8) place(e) just(right))
    text(1.1 21 "58% variance explained", color(gs8) place(e) just(right))
    name(screeplot)
    ;
#delimit cr 

** Principal Components Analysis --> Linear combnation without error terms
pca $xlist , mineigen(1)
** Orthogonal rotation 
rotate, varimax blanks(0.3)
** Oblique rotation 
rotate, promax blanks(0.3)

** Post PCA plot for exploration 
scoreplot, mlabel($xlist) name(pca_scores)

** Add loadings to dataset 
estat loadings 
predict pca1 pca2 pca3, score

** KMO measure of sampling adequacy
** Is a correlation matrix suitable for FA / PCA ??
** Tabulates the estimated common variance in the correlation matrix...
** Realistically --> we're looking for 0.65 (ish) and higher 
 estat kmo 
