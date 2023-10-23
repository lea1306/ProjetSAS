/* Importation des données de l'election 2017 */
data WORK.BASE17;
    infile '/home/u62532621/Projet_SAS/A2017.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

    informat Région $200. Département $200. Commune $200. Nb_votant Nb_inscrit Nb_noexp Rapport_noexp best32. ;
    format Région Département Commune $200. Nb_votant Nb_inscrit Nb_noexp Rapport_noexp best12. ;

    input Région $ Département $ Commune $ Nb_votant Nb_inscrit Nb_noexp Rapport_noexp ;

    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/* Importation des données de l'election 2022 */
data WORK.BASE22;
    infile '/home/u62532621/Projet_SAS/A2022.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

    informat Région $200. Département $200. Commune $200. Nb_votant Nb_inscrit Nb_noexp Rapport_noexp best32. ;
    format Région Département Commune $200. Nb_votant Nb_inscrit Nb_noexp Rapport_noexp best12. ;

    input Région $ Département $ Commune $ Nb_votant Nb_inscrit Nb_noexp Rapport_noexp ;

    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/* Création d'une clé par concaténation de Département et Commune */
%macro processData(baseIn, baseOut, year);
	data &baseOut.;
		set &baseIn.;
		cle = trim(left(Département)) || "-" || trim(left(Commune));
		rename 
			Nb_votant = Nb_votant&year.
			Nb_inscrit = Nb_inscrit&year.
			Nb_noexp = Nb_noexp&year.
			Rapport_noexp = Rapport_noexp&year.;
	run;
%mend processData;

%processData(BASE17, BASE17_2, 17);
%processData(BASE22, BASE22_2, 22);

/* Jointure des deux bases */
proc sql;
	create table data as
	select *
	from BASE17_2
	inner join BASE22_2 on BASE17_2.cle = BASE22_2.cle;
run;

/* Évolution du Rapport_Noexp par Région en pourcentage */
proc sql;
	select Région, 
		   (sum(Rapport_Noexp22) - sum(Rapport_Noexp17))/sum(Rapport_Noexp17)*100 as Évolution
	from data
	group by Région;
run;

/* Évolution du Rapport_Noexp par département en pourcentage */
proc sql;
	select Département, 
		   (sum(Rapport_Noexp22) - sum(Rapport_Noexp17))/sum(Rapport_Noexp17)*100 as Évolution
	from data
	group by Département;
run;

/* Évolution du Rapport_Noexp par Commune en pourcentage */
proc sql;
	select Commune, 
		   (sum(Rapport_Noexp22) - sum(Rapport_Noexp17))/sum(Rapport_Noexp17)*100 as Évolution
	from data
	group by Commune;
run;


/* Décompte de l'évolution 2 */ 

/* région */ 
proc sql;
    create table temp_evolution as
    select Région, 
           (sum(Nb_Noexp22) - sum(Nb_Noexp17)) as Évolution
	from data
    group by Région;
    
    select 
           sum(case when Évolution > 0 then 1 else 0 end) as augmentation,
           sum(case when Évolution < 0 then 1 else 0 end) as Diminution
    from temp_evolution;
quit;

/* Département */ 
proc sql;
    create table temp_evolution as
    select Département, 
           ((sum(Nb_Noexp22) - sum(Nb_Noexp17))) as Évolution
    from data
    group by Département;
    
    select 
           sum(case when Évolution > 0 then 1 else 0 end) as augmentation,
           sum(case when Évolution < 0 then 1 else 0 end) as Diminution
    from temp_evolution;
quit;

/* Macron Commune */
proc sql;
    create table temp_evolution as
    select Commune, 
           ((sum(Nb_Noexp22) - sum(Nb_Noexp17))) as Évolution
    from data
    group by Commune;
    
    select
           sum(case when Évolution > 0 then 1 else 0 end) as augmentation,
           sum(case when Évolution < 0 then 1 else 0 end) as Diminution
    from temp_evolution;
quit;
