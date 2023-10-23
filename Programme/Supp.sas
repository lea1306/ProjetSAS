/*------------ PROJET SAS ------------*/

/* Importation des données de l'election 2017 : vote */
data WORK.BASE17;
    infile '/home/u62532621/Projet_SAS/E2017.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

    informat "Région"N $200. "Département"N $200. Commune $200. Nom_Candidat $8. Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N best32. ;
    format "Région"N "Département"N Commune Nom_Candidat $200. Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N best12. ;

    input "Région"N  $ "Département"N  $ Commune  $ Nom_Candidat  $ Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N ;

    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/* Importation des données de l'election 2022 : vote */
data WORK.BASE22;
    infile '/home/u62532621/Projet_SAS/E2022.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

    informat "Région"N $200. "Département"N $200. Commune $200. Nom_Candidat $8. Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N best32. ;
    format "Région"N "Département"N Commune $200. Nom_Candidat $8. Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N best12. ;

    input "Région"N $ "Département"N $ Commune $ Nom_Candidat $ Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N ;

    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/* Création d'une clé par concaténation de Département, Commune et Nom_Candidat, et renommage de variables */
%macro processData(baseIn, baseOut, year);
	data &baseOut.;
		set &baseIn.;
		cle = trim(left("Département"N)) || "-" || trim(left(Commune)) || "-" || trim(left(Nom_Candidat));
		rename 
			Rapport_Inscrit = Rapport_Inscrit&year.
			Rapport_Exprimé = Rapport_Exprimé&year.
			Nombre_de_voix = Nombre_de_voix&year.;
	run;
%mend processData;

%processData(base17, base17_2, 17);
%processData(base22, base22_2, 22);

/* Jointure des deux bases */
proc sql;
	create table data as
	select *
	from base17_2
	inner join base22_2 on base17_2.cle = base22_2.cle;
run;

/* Début de l'analyse */

/* Création de tables pour chaque candidat */
proc sql;
	create table macron as
	select *
	from data
	where Nom_Candidat = 'MACRON';
run;

proc sql;
	create table lepen as
	select *
	from data
	where Nom_Candidat = 'LE PEN';
run;

/* Évolution du Rapport_Inscrit par candidat par département en pourcentage */
proc sql;
	create table macronevolution as
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	group by Département;
run;

proc sql;
    create table lepenevolution as
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	group by Département;
run;

proc sgplot data=lepenevolution;
  vbar Département / response=Évolution ;
                  
  xaxis display=(nolabel);
  yaxis label="Évolution (%)";
  title "Évolution du Rapport d'Inscrits par Département pour LE PEN (2017-2022)";
run;

proc sgplot data=macronevolution;
  vbar Département / response=Évolution ;
                  
  xaxis display=(nolabel);
  yaxis label="Évolution (%)";
  title "Évolution du Rapport d'Inscrits par Département pour MACRON (2017-2022)";
run;

/***** ANALYSE DES FREQUENCES ET STATISTIQUES DESCRIPTIVES *****/

/* Répartition géographique des votes en 2017*/
proc freq data=base17;
  tables Département;
run;

/* Répartition géographique des votes en 2022*/
proc freq data=base22;
  tables Département;
run;


/* Distribution des voix pour MACRON */
proc means data=macron;
  var Nombre_de_voix17 Nombre_de_voix22;
run;

/* Distribution des voix pour LEPEN */

proc means data=lepen;
  var Nombre_de_voix17 Nombre_de_voix22;
run;