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

/* Évolution du Rapport_Inscrit par candidat par Région en pourcentage */
proc sql;
	select Région, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	group by Région;
run;

proc sql;
	select Région, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	group by Région;
run;

/* Évolution du Rapport_Inscrit par candidat par département en pourcentage */
proc sql;
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	group by Département;
run;

proc sql;
	select Département, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	group by Département;
run;

/* Évolution du Rapport_Inscrit par candidat par Commune en pourcentage */
proc sql;
	select Commune, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from macron
	group by Commune;
run;

proc sql;
	select Commune, 
		   (sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17))/sum(Rapport_Inscrit17)*100 as Évolution
	from lepen
	group by Commune;
run; 


/* Décompte de l'évolution */ 
/* Macron région */ 

proc sql;
    create table temp_evolution as
    select Région, 
           ((sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17)) / sum(Rapport_Inscrit17)*100) as Évolution
    from macron
    group by Région;
    
    select
           sum(case when Évolution > 0 then 1 else 0 end) as Macron_aug_Reg,
           sum(case when Évolution < 0 then 1 else 0 end) as Macron_dim_Reg
    from temp_evolution
quit;

/* Le Pen région */ 
proc sql;
    create table temp_evolution as
    select Région, 
           ((sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17)) / sum(Rapport_Inscrit17)*100) as Évolution
    from lepen
    group by Région;
    
    select 
           sum(case when Évolution > 0 then 1 else 0 end) as Lepen_aug_Reg,
           sum(case when Évolution < 0 then 1 else 0 end) as Lepen_dim_Reg
    from temp_evolution;
quit;

/* Macron Département */ 
proc sql;
    create table temp_evolution as
    select Département, 
           ((sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17)) / sum(Rapport_Inscrit17)*100) as Évolution
    from macron
    group by Département;
    
    select
           sum(case when Évolution > 0 then 1 else 0 end) as Macron_aug_Dep,
           sum(case when Évolution < 0 then 1 else 0 end) as Macron_dim_Dep
    from temp_evolution
quit;

/* Le Pen Département */ 
proc sql;
    create table temp_evolution as
    select Département, 
           ((sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17)) / sum(Rapport_Inscrit17)*100) as Évolution
    from lepen
    group by Département;
    
    select 
           sum(case when Évolution > 0 then 1 else 0 end) as Lepen_aug_Dep,
           sum(case when Évolution < 0 then 1 else 0 end) as Lepen_dim_Dep
    from temp_evolution;
quit;

/* Macron Commune */ 
proc sql;
    create table temp_evolution as
    select Commune, 
           ((sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17)) / sum(Rapport_Inscrit17)*100) as Évolution
    from macron
    group by Commune;
    
    select
           sum(case when Évolution > 0 then 1 else 0 end) as Macron_aug_Com,
           sum(case when Évolution < 0 then 1 else 0 end) as Macron_dim_Com
    from temp_evolution
quit;

/* Le Pen Commune */
proc sql;
    create table temp_evolution as
    select Commune, 
           ((sum(Rapport_Inscrit22) - sum(Rapport_Inscrit17)) / sum(Rapport_Inscrit17)*100) as Évolution
    from lepen
    group by Commune;
    
    select 
           sum(case when Évolution > 0 then 1 else 0 end) as Lepen_aug_Com,
           sum(case when Évolution < 0 then 1 else 0 end) as Lepen_dim_Com
    from temp_evolution;
quit;

