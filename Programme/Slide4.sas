/*------------ PROJET SAS ------------*/

/* Importation des données de l'election 2017 : vote */
data WORK.BASE17;
    infile '/home/u62535729/Projet_SAS/E2017.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

    informat "Région"N $200. "Département"N $200. Commune $200. Nom_Candidat $8. Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N best32. ;
    format "Région"N "Département"N Commune Nom_Candidat $200. Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N best12. ;

    input "Région"N  $ "Département"N  $ Commune  $ Nom_Candidat  $ Nombre_de_voix Rapport_Inscrit "Rapport_Exprimé"N ;

    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/* Importation des données de l'election 2022 : vote */
data WORK.BASE22;
    infile '/home/u62535729/Projet_SAS/E2022.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

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

/* 5 meilleures et pires évolutions du Rapport_Inscrit par candidat par Région en pourcentage */
/* Macron */
proc sql;
	create table macron_reg_desc as
	select Région, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	where Région is not null
	group by Région
	order by Évolution desc;
run;
data macron_5_best_reg;
	set macron_reg_desc (obs = 5);
run;

proc sql;
	create table macron_reg_asc as
	select Région, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	where Région is not null
	group by Région
	order by Évolution asc;
run;
data macron_5_pire_reg;
	set macron_reg_asc (obs = 5);
run;

/* Le Pen */
proc sql;
	create table lepen_reg_desc as
	select Région, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	where Région is not null
	group by Région
	order by Évolution desc;
run;
data lepen_5_best_reg;
	set lepen_reg_desc (obs = 5);
run;

proc sql;
	create table lepen_reg_asc as
	select Région, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	where Région is not null
	group by Région
	order by Évolution asc;
run;
data lepen_5_pire_reg;
	set lepen_reg_asc (obs = 5);
run;

/* 5 meilleures et pires évolutions du Rapport_Inscrit par candidat par Département en pourcentage */
/* Macron */
proc sql;
	create table macron_dept_desc as
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	group by Département
	order by Évolution desc;
run;
data macron_5_best_dept;
	set macron_dept_desc (obs = 5);
run;

proc sql;
	create table macron_dept_asc as
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	group by Département
	order by Évolution asc;
run;
data macron_5_pire_dept;
	set macron_dept_asc (obs = 5);
run;

/* Le Pen */
proc sql;
	create table lepen_dept_desc as
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	group by Département
	order by Évolution desc;
run;
data lepen_5_best_dept;
	set lepen_dept_desc (obs = 5);
run;

proc sql;
	create table lepen_dept_asc as
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	group by Département
	order by Évolution asc;
run;
data lepen_5_pire_dept;
	set lepen_dept_asc (obs = 5);
run;

/* 5 meilleures et pires évolutions du Rapport_Inscrit par candidat par Commune en pourcentage */
/* Macron */
proc sql;
	create table macron_comm_desc as
	select Commune, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	group by Commune
	having Évolution is not null
	order by Évolution desc;
run;
data macron_5_best_comm;
	set macron_comm_desc (obs = 5);
run;

proc sql;
	create table macron_comm_asc as
	select Commune, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	group by Commune
	having Évolution is not null
	order by Évolution asc;
run;
data macron_5_pire_comm;
	set macron_comm_asc (obs = 5);
run;

/* Le Pen */
proc sql;
	create table lepen_comm_desc as
	select Commune, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	group by Commune
	having Évolution is not null
	order by Évolution desc;
run;
data lepen_5_best_comm;
	set lepen_comm_desc (obs = 5);
run;

proc sql;
	create table lepen_comm_asc as
	select Commune, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	group by Commune
	having Évolution is not null
	order by Évolution asc;
run;
data lepen_5_pire_comm;
	set lepen_comm_asc (obs = 5);
run;