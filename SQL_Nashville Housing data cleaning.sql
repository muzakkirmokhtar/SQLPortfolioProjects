/*
Cleaning Data in SQL Queries
Import data from excel into sql server
*/

SELECT *
FROM PortfolioProject1..NashvilleHousing

-- Standardize Date Format

SELECT SaleDate
FROM PortfolioProject1..NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

SELECT CAST(SaleDate AS date)
FROM PortfolioProject1..NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate date

-- Populate Property Address data

SELECT *
FROM PortfolioProject1..NashvilleHousing
ORDER BY ParcelID

-- perform self join to return address in NULL column

SELECT a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress,
ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject1..NashvilleHousing AS a
JOIN PortfolioProject1..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL
ORDER BY a.PropertyAddress

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject1..NashvilleHousing AS a
JOIN PortfolioProject1..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]


-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioProject1..NashvilleHousing
ORDER BY ParcelID

-- method 1 separating using SUBSTRING

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
FROM PortfolioProject1..NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1,
LEN(PropertyAddress)) AS City
FROM PortfolioProject1..NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)
AS PropertySplitAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1,
LEN(PropertyAddress)) AS PropertySplitCity
FROM PortfolioProject1..NashvilleHousing

-- substring create new columns

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress =
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity =
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1,
LEN(PropertyAddress))

SELECT *
FROM PortfolioProject1..NashvilleHousing

-- method 2 separating using PARSENAME

SELECT OwnerAddress
FROM PortfolioProject1..NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitState
FROM PortfolioProject1..NashvilleHousing
ORDER BY ParcelID

-- PARSENAME create new columns

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM PortfolioProject1..NashvilleHousing
ORDER BY ParcelID

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject1..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM PortfolioProject1..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant =
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END

SELECT *
FROM PortfolioProject1..NashvilleHousing
ORDER BY ParcelID

-- Remove Duplicates using CTE

WITH RowNumCTE AS
(
SELECT *,
ROW_NUMBER() OVER
(
PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
ORDER BY ParcelID
) AS Row_Num
FROM PortfolioProject1..NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE Row_Num > 1
ORDER BY PropertyAddress

WITH RowNumCTE AS
(
SELECT *,
ROW_NUMBER() OVER
(
PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
ORDER BY ParcelID
) AS Row_Num
FROM PortfolioProject1..NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE Row_Num > 1

-- Delete Unused Columns

SELECT *
FROM PortfolioProject1..NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict