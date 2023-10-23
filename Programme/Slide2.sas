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

/*****************************************************/
/* Évolution du Rapport_Inscrit par candidat par Région en pourcentage et somme des votes */

proc sql;
	create table evol_M as
	select Région, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as evolution_M,
		   sum(Nombre_de_voix17) as NB_2017_M,
		   sum(Nombre_de_voix22) as NB_2022_M
	from macron
	group by Région;
run;


proc sql;
	create table evol_L as
	select Région, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as evolution_L,
		    sum(Nombre_de_voix17) as NB_2017_L,
		    sum(Nombre_de_voix22) as NB_2022_L
	from lepen
	group by Région;
run;

/* Carte évolution de la majorité dans les Région */

/*Jointure des bases evol_L et evol_M*/
proc sql;
	create table Evol as
	select  EVOL_M.Région,NB_2017_L, NB_2017_M, NB_2022_M, NB_2022_L
	from  EVOL_M
	inner join  EVOL_L on EVOL_M.Région = EVOL_L.Région;
run;

data Majorite;
   set Evol;
   
   /* Define the majorities for 2017 and 2022 */
   if NB_2017_L > NB_2017_M then M_2017 = 'Lepen ';
   else M_2017 = 'Macron';
   
   if NB_2022_L > NB_2022_M then M_2022 = 'Lepen ';
   else M_2022 = 'Macron';

   /* Determine the evolution of the majority based on the previous definitions */
   if M_2017 = 'Macron' and M_2022 = 'Macron' then Evol_Majorite = 1;
   else if M_2017 = 'Lepen' and M_2022 = 'Lepen' then Evol_Majorite = 2;
   else if M_2017 = 'Macron' and M_2022 = 'Lepen' then Evol_Majorite = 3;
   else if M_2017 = 'Lepen' and M_2022 = 'Macron' then Evol_Majorite = 4;

   keep Région M_2017 M_2022 Evol_Majorite;
   /*Cas de l'évolution*/
/* 1 : Majorité pour macron de 2017 à 2022
   2 : Majorité pour lepen de 2017 à 2022
   3 : Majorité changeante macron -> lepen
   4 : Majorité changeante lepen -> macron */
run;

proc print data=Majorite (obs=10); 
run;

proc freq data=Majorite;
   tables Evol_Majorite;
run;

/*****************************************************/
/* Évolution du Rapport_Inscrit par candidat par département en pourcentage et somme des votes */
/*****************************************************/

proc sql;
	create table evol_M as
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as evolution_M,
		   sum(Nombre_de_voix17) as NB_2017_M,
		   sum(Nombre_de_voix22) as NB_2022_M
	from macron
	group by Département;
run;


proc sql;
	create table evol_L as
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as evolution_L,
		    sum(Nombre_de_voix17) as NB_2017_L,
		    sum(Nombre_de_voix22) as NB_2022_L
	from lepen
	group by Département;
run;

/* Carte évolution de la majorité dans les départements */

/*Jointure des bases evol_L et evol_M*/
proc sql;
	create table Evol as
	select  EVOL_M.Département,NB_2017_L, NB_2017_M, NB_2022_M, NB_2022_L
	from  EVOL_M
	inner join  EVOL_L on EVOL_M.Département = EVOL_L.Département;
run;

data Majorite;
   set Evol;
   
   /* Define the majorities for 2017 and 2022 */
   if NB_2017_L > NB_2017_M then M_2017 = 'Lepen ';
   else M_2017 = 'Macron';
   
   if NB_2022_L > NB_2022_M then M_2022 = 'Lepen ';
   else M_2022 = 'Macron';

   /* Determine the evolution of the majority based on the previous definitions */
   if M_2017 = 'Macron' and M_2022 = 'Macron' then Evol_Majorite = 1;
   else if M_2017 = 'Lepen' and M_2022 = 'Lepen' then Evol_Majorite = 2;
   else if M_2017 = 'Macron' and M_2022 = 'Lepen' then Evol_Majorite = 3;
   else if M_2017 = 'Lepen' and M_2022 = 'Macron' then Evol_Majorite = 4;

   keep Département M_2017 M_2022 Evol_Majorite;
   /*Cas de l'évolution*/
/* 1 : Majorité pour macron de 2017 à 2022
   2 : Majorité pour lepen de 2017 à 2022
   3 : Majorité changeante macron -> lepen
   4 : Majorité changeante lepen -> macron */
run;

proc print data=Majorite (obs=10); 
run;

proc freq data=Majorite;
   tables Evol_Majorite;
run;
/*****************************************************/

/*****************************************************/
/* Évolution du Rapport_Inscrit par candidat par Commune en pourcentage et somme des votes */
/*****************************************************/

proc sql;
	create table evol_M as
	select Commune, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as evolution_M,
		   sum(Nombre_de_voix17) as NB_2017_M,
		   sum(Nombre_de_voix22) as NB_2022_M
	from macron
	group by Commune;
run;


proc sql;
	create table evol_L as
	select Commune, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as evolution_L,
		    sum(Nombre_de_voix17) as NB_2017_L,
		    sum(Nombre_de_voix22) as NB_2022_L
	from lepen
	group by Commune;
run;

/*****************************************************/

/*Jointure des bases evol_L et evol_M*/
proc sql;
	create table Evol as
	select  EVOL_M.Commune,NB_2017_L, NB_2017_M, NB_2022_M, NB_2022_L
	from  EVOL_M
	inner join  EVOL_L on EVOL_M.Commune = EVOL_L.Commune;
run;

data Majorite;
   set Evol;
   
   /* Define the majorities for 2017 and 2022 */
   if NB_2017_L > NB_2017_M then M_2017 = 'Lepen ';
   else M_2017 = 'Macron';
   
   if NB_2022_L > NB_2022_M then M_2022 = 'Lepen ';
   else M_2022 = 'Macron';

   /* Determine the evolution of the majority based on the previous definitions */
   if M_2017 = 'Macron' and M_2022 = 'Macron' then Evol_Majorite = 1;
   else if M_2017 = 'Lepen' and M_2022 = 'Lepen' then Evol_Majorite = 2;
   else if M_2017 = 'Macron' and M_2022 = 'Lepen' then Evol_Majorite = 3;
   else if M_2017 = 'Lepen' and M_2022 = 'Macron' then Evol_Majorite = 4;

   keep Commune M_2017 M_2022 Evol_Majorite;
   /*Cas de l'évolution*/
/* 1 : Majorité pour macron de 2017 à 2022
   2 : Majorité pour lepen de 2017 à 2022
   3 : Majorité changeante macron -> lepen
   4 : Majorité changeante lepen -> macron */
run;

proc print data=Majorite (obs=10); 
run;

proc freq data=Majorite;
   tables Evol_Majorite;
run;
