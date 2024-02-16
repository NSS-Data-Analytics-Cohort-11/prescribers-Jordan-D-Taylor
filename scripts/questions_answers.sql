-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) AS claim_summation
FROM prescription
GROUP BY npi
ORDER BY claim_summation DESC
LIMIT 10;

-- Answer: npi = 1881634483, number of claims = 99707

-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT prescriber.npi, SUM(prescription.total_claim_count) AS claim_summation, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
FROM prescriber
INNER JOIN prescription
	ON prescriber.npi = prescription.npi
GROUP BY prescriber.npi, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
ORDER BY claim_summation DESC
LIMIT 10;

-- Answer: Bruce Pendley, Family Practice, 99707



-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT SUM(prescription.total_claim_count) AS claim_summation, prescriber.specialty_description
FROM prescriber
INNER JOIN prescription
	ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
ORDER BY claim_summation DESC
LIMIT 10;

-- Answer: Family Practice

-- 2b. Which specialty had the most total number of claims for opioids?

SELECT SUM(prescription.total_claim_count) AS claim_summation, prescriber.specialty_description, drug.opioid_drug_flag
FROM prescription
INNER JOIN prescriber
	ON prescriber.npi = prescription.npi
INNER JOIN drug
	ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag IN('Y')
GROUP BY prescriber.specialty_description, drug.opioid_drug_flag
ORDER BY claim_summation DESC
LIMIT 10;

-- Answer: Nurse Practitioner

-- 2c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

-- 2d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?



-- 3a. Which drug (generic_name) had the highest total drug cost?

SELECT SUM(prescription.total_drug_cost_ge65) AS sum_total_drug_cost, drug.generic_name
FROM prescription
INNER JOIN drug
	ON prescription.drug_name = drug.drug_name
WHERE prescription.total_drug_cost_ge65 IS NOT NULL
GROUP BY drug.generic_name
ORDER BY sum_total_drug_cost DESC
LIMIT 10;

-- Answer: "INSULIN GLARGINE,HUM.REC.ANLOG"

-- 3b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT drug.generic_name, ROUND(SUM(prescription.total_drug_cost)/SUM(prescription.total_day_supply),2) AS sum_total_drug_cost_per_day
FROM prescription
INNER JOIN drug
	ON prescription.drug_name = drug.drug_name
GROUP BY drug.generic_name
ORDER BY sum_total_drug_cost_per_day DESC
LIMIT 10;

-- Answer: "C1 ESTERASE INHIBITOR"



-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug;

-- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(MONEY(prescription.total_drug_cost)) AS total_drug_cost_sum,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug
INNER JOIN prescription
	ON drug.drug_name = prescription.drug_name
GROUP BY drug_type
ORDER BY total_drug_cost_sum DESC;

-- Answer: Opioids



-- 5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

-- Answer: 56

-- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsa.cbsaname, SUM(population.population) AS population_sum
FROM cbsa
INNER JOIN population
	ON cbsa.fipscounty = population.fipscounty
GROUP BY cbsa.cbsaname
ORDER BY population_sum DESC;

-- Answer: largest = "Nashville-Davidson--Murfreesboro--Franklin, TN", smallest = "Morristown, TN"

-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT SUM(population.population) AS population, fips_county.county
FROM fips_county
LEFT JOIN cbsa
	ON fips_county.fipscounty = cbsa.fipscounty
LEFT JOIN population
	ON fips_county.fipscounty = population.fipscounty
WHERE cbsa.cbsa IS NULL
AND population IS NOT NULL
GROUP BY fips_county.county, population
ORDER BY population DESC;

-- ANSWER: Sevier, 95523



-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000

-- Answer: See Query

-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, prescription.total_claim_count,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN opioid_drug_flag = 'N' THEN 'non opioid'
		ELSE 'neither'
	END AS drug_type
FROM drug
INNER JOIN prescription
	ON prescription.drug_name = drug.drug_name
WHERE total_claim_count > 3000;

-- Answer: See Query

-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT prescription.drug_name, prescription.total_claim_count, CONCAT(prescriber.nppes_provider_first_name, ' ', prescriber.nppes_provider_last_org_name) AS prescriber_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN opioid_drug_flag = 'N' THEN 'non opioid'
		ELSE 'neither'
	END AS drug_type
FROM drug
INNER JOIN prescription
	ON prescription.drug_name = drug.drug_name
INNER JOIN prescriber
	ON prescriber.npi = prescription.npi
WHERE total_claim_count > 3000;

-- Answer: See Query



-- The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.



--     7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

-- save before running this one

--     7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

