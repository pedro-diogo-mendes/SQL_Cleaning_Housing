SELECT *
FROM DataCleaning.dbo.NashvilleHousing
ORDER BY [UniqueID ]



-- Standardize Date Format
-- The table had this format "2013-04-09 00:00:00.000"
-- I wanted to change it to just the date "2013-04-09"

ALTER TABLE DataCleaning.dbo.NashvilleHousing
ALTER COLUMN SaleDate DATE

--------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data that is NULL
-- I noticed that there are some NULL values in the "PropertyAdress" column. So I'm going to check if I can fill it out or not.
-- While searching the data, I noticed that the "ParcellID" column is repeated and the same code contains the same address.
-- So I'm going to populate the NULL values with the addresses where the code in the "ParcellID" column is the same.

SELECT ParcelID, PropertyAddress
FROM DataCleaning.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT ParcelID, PropertyAddress
FROM DataCleaning.dbo.NashvilleHousing
WHERE ParcelID = '025 07 0 031.00'
ORDER BY ParcelID

-- Next, I'm going to do a Self Join, where I will join the table with itself to populate the column.

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress) -- Here ISNULL is saying that if the column in table A is NULL, we want you to replace it with the addresses in table B.
FROM DataCleaning.dbo.NashvilleHousing AS A
JOIN DataCleaning.dbo.NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ] -- I've set this column to be different to make sure I'm not populating repeated rows, as this column are unique values.
WHERE A.PropertyAddress IS NULL


UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM DataCleaning.dbo.NashvilleHousing AS A
JOIN DataCleaning.dbo.NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

--------------------------------------------------------------------------------------------------------------------------------

-- Breaking Out Address Into Individual Columns (Address, City) From The Collumn "PropertyAddress"

SELECT PropertyAddress
FROM DataCleaning.dbo.NashvilleHousing

-- I noticed that the state is separated by the comma delimiter ",".

SELECT 
	SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
	SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM DataCleaning.dbo.NashvilleHousing


-- I'm now going to create the two new columns.

ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD PropertyAddressSplit NVARCHAR(255);

UPDATE DataCleaning.dbo.NashvilleHousing
SET PropertyAddressSplit = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);


ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD PropertyCitySplit NVARCHAR(255);

UPDATE DataCleaning.dbo.NashvilleHousing
SET PropertyCitySplit = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));


SELECT *
FROM DataCleaning.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------------------------

-- Breaking Out Address Into Individual Columns (Address, City, State) From The Column "OwnerAddress"
-- Using Another Technic

SELECT OwnerAddress
FROM DataCleaning.dbo.NashvilleHousing

-- The PARSENAME function only checks for Endpoints and not for commas, so we have to use the REPLACE function together to replace commas with periods.

SELECT
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1),
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3)
FROM DataCleaning.dbo.NashvilleHousing


ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD OwnerState NVARCHAR(50);

ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD OwnerCity NVARCHAR(50);

ALTER TABLE DataCleaning.dbo.NashvilleHousing
ADD OwnerAddressSplit NVARCHAR(255);

UPDATE DataCleaning.dbo.NashvilleHousing
SET OwnerState = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1);

UPDATE DataCleaning.dbo.NashvilleHousing
SET OwnerCity = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE DataCleaning.dbo.NashvilleHousing
SET OwnerAddressSplit = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3);


SELECT *
FROM DataCleaning.dbo.NashvilleHousing


-----------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "SoldAsVacant"

SELECT DISTINCT (SoldAsVacant), COUNT (SoldAsVacant)
FROM DataCleaning.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
,
	CASE
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
		END
FROM DataCleaning.dbo.NashvilleHousing


UPDATE DataCleaning.dbo.NashvilleHousing
SET SoldAsVacant = CASE
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
		END


-----------------------------------------------------------------------------------------------------------------------------


-- Remove Duplicates
-- I'm going to assume that if the "ParcelID", "PropertyAddress", "SalePrice" and "LegalReference" columns are duplicated, then we will have to delete 1 of the rows.

WITH CTE_ROW_NUM AS
(
	SELECT *,
		ROW_NUMBER ()
			OVER
			(
				PARTITION BY
				ParcelID,
				PropertyAddress,
				SalePrice,
				LegalReference
				ORDER BY
					UniqueID
			) AS row_num
	FROM DataCleaning.dbo.NashvilleHousing
)
SELECT *
FROM CTE_ROW_NUM
WHERE row_num > 1
ORDER BY row_num DESC


-- Now I'm going to delete these duplicates

WITH CTE_ROW_NUM AS
(
	SELECT *,
		ROW_NUMBER ()
			OVER
			(
				PARTITION BY
				ParcelID,
				PropertyAddress,
				SalePrice,
				LegalReference
				ORDER BY
					UniqueID
			) AS row_num
	FROM DataCleaning.dbo.NashvilleHousing
)
DELETE
FROM CTE_ROW_NUM
WHERE row_num > 1


-----------------------------------------------------------------------------------------------------------------------------

-- Deleting unused column

ALTER TABLE DataCleaning.dbo.NashvilleHousing
DROP COLUMN PropertyAddress


SELECT *
FROM DataCleaning.dbo.NashvilleHousing