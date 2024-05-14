-- EJERCICIO 2 - Consultas para explotar la información base de datos RNA-SEQ

-- 1. Resultado agrupado de los pacientes por las propiedades sexo y rango de edad. 
-- AYUDA: Se puede hacer más de un JOIN sobre la misma tabla. 

SELECT p_sexo.nombre AS sexo, p_rango_edad.nombre AS rango_de_edad, COUNT(DISTINCT m.codigo) AS n_muestras
FROM b3b2_muestra m INNER JOIN b3b2_muestra_propiedad mp_sexo ON m.codigo = mp_sexo.muestra
INNER JOIN b3b2_propiedad p_sexo ON mp_sexo.propiedad = p_sexo.id
INNER JOIN b3b2_muestra_propiedad mp_rango_edad ON m.codigo = mp_rango_edad.muestra
INNER JOIN b3b2_propiedad p_rango_edad ON mp_rango_edad.propiedad = p_rango_edad.id
WHERE p_sexo.tipo = 'sexo' AND p_rango_edad.tipo = 'rango de edad'
GROUP BY p_sexo.nombre, p_rango_edad.nombre
ORDER BY p_sexo.nombre, p_rango_edad.nombre;

-- 2. Número de genes que participan en la rutas que contenta la palabra 'platelet'. Simplemente hay que devolver el número.    

SELECT COUNT(DISTINCT pg.gen) AS numero_genes
FROM b3b2_gen_pathway pg
INNER JOIN b3b2_pathway p ON pg.pathway = p.codigo
WHERE p.descripcion LIKE '%platelet%';

-- 3. Muestras de las que no tenemos resultados de expresión. Basta con devolver el código de la muestra.

SELECT m.codigo
FROM b3b2_muestra m
left join b3b2_expresion e on m.codigo = e.muestra
WHERE e.muestra is null;

-- 4. Media de expresión de los genes secuenciados. Devolverá el gene_symbol y la media de expresión global.

SELECT g.gene_symbol, AVG(e.expresion) AS media_expresion
FROM b3b2_gen g
INNER JOIN b3b2_expresion e ON g.gene_ensembl = e.gen
GROUP BY g.gene_symbol;

-- 5. Número de pathways de los genes que tienen media de expresión mayor de 25. Sólo debe devolver un número.

SELECT COUNT(DISTINCT gp.pathway) AS numero_pathways
FROM b3b2_gen g
INNER JOIN b3b2_gen_pathway gp ON g.gene_ensembl = gp.gen
INNER JOIN b3b2_pathway p ON gp.pathway = p.codigo
WHERE g.gene_ensembl IN (
    SELECT e.gen
    FROM b3b2_expresion e
    GROUP BY e.gen
    HAVING AVG(e.expresion) > 25
);

-- 6. Muestras de las que no tenemos alguna propiedad (o sexo o rango de edad). Basta con devolver el código de la muestra.

SELECT DISTINCT m.codigo
FROM b3b2_muestra m
LEFT JOIN b3b2_muestra_propiedad mp_sexo ON m.codigo = mp_sexo.muestra
AND mp_sexo.propiedad IN (SELECT id FROM b3b2_propiedad WHERE tipo = 'sexo')
LEFT JOIN b3b2_muestra_propiedad mp_rango_edad ON m.codigo = mp_rango_edad.muestra
AND mp_rango_edad.propiedad IN (SELECT id FROM b3b2_propiedad WHERE tipo = 'rango de edad')
WHERE mp_sexo.muestra IS NULL OR mp_rango_edad.muestra IS NULL;

-- 7. Número de muestras por run.

SELECT r.nombre AS run, COUNT(mr.muestra) AS numero_muestras
FROM beb2_run r
INNER JOIN beb2_muestra_run mr ON r.nombre = mr.run
GROUP BY r.nombre;

-- 8. Consulta que devuelva los genes cuyo log2foldchange sea mayor de 1 en valor absoluto entre muestras con sexo hombre y muestras con sexo mujer. 
-- Deberá de devolver el gene_symbol y el valor de log2foldchange.

SELECT g.gene_symbol, LOG2(media_expresion_hombre / media_expresion_mujer) AS log2foldchange
FROM b3b2_gen g
INNER JOIN (
    SELECT e.gen, AVG(e.expresion) AS media_expresion_hombre
    FROM b3b2_expresion e
    INNER JOIN b3b2_muestra_propiedad mp ON e.muestra = mp.muestra
    INNER JOIN b3b2_propiedad p ON mp.propiedad = p.id
    WHERE p.tipo = 'sexo' AND p.nombre = 'hombre'
    GROUP BY e.gen
) AS media_expresion_h ON g.gene_ensembl = media_expresion_h.gen
INNER JOIN (
    SELECT e.gen, AVG(e.expresion) AS media_expresion_mujer
    FROM b3b2_expresion e
    INNER JOIN b3b2_muestra_propiedad mp ON e.muestra = mp.muestra
    INNER JOIN b3b2_propiedad p ON mp.propiedad = p.id
    WHERE p.tipo = 'sexo' AND p.nombre = 'mujer'
    GROUP BY e.gen
) AS media_expresion_m ON g.gene_ensembl = media_expresion_m.gen
HAVING ABS(log2foldchange) > 1;