local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DATASTORE_NAME = "Dataaaaaa"

local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

local function loadPlayerData(player)
	local hddFolder = player:FindFirstChild("HDD")
	if not hddFolder then
		hddFolder = Instance.new("Folder")
		hddFolder.Name = "HDD"
		hddFolder.Parent = player
	end

	local success, data = pcall(function()
		return dataStore:GetAsync(tostring(player.UserId))
	end)

	print(success)
	print(data)

	if not success or not data then
		for _, child in ipairs(hddFolder:GetDescendants()) do
			child:Destroy()
		end
		return
	end
	
	local function checkDuplicateName(parentFolder, itemName, currentElement)
		for _, item in ipairs(parentFolder:GetChildren()) do
			if item.Name == itemName and item ~= currentElement then
				local itemAdress = item:FindFirstChild("Adress")
				if itemAdress then
					local itemParentAdress = string.sub(itemAdress.Value, 1, -(string.len(itemName) + 2))
					local elementAdress = currentElement:FindFirstChild("Adress")
					local elementParentAdress = string.sub(elementAdress.Value, 1, -(string.len(itemName) + 2))
					if itemParentAdress == elementParentAdress then
						return true
					end
				end
			end
		end
		return false
	end

	local function moveToParentFolder(element, parentFolder, itemName)
		element.Parent = parentFolder
		element.Name = itemName
		local adress = element:FindFirstChild("Adress")
		if adress then
			adress:Destroy()
		end
	end

	local function placeElementsWithDelay(elements, parentFolder, delay)
		local index = 1
		local totalElements = #elements

		local function placeNextElement()
			if index <= totalElements then
				local element = elements[index]
				local adress = element:FindFirstChild("Adress")
				if adress then
					local parentNames = string.split(adress.Value, "/")
					local parentFolder = hddFolder

					-- Hedef klasörün adresini bulana kadar klasörleri kontrol et
					for i = 2, #parentNames - 1 do
						local folderName = parentNames[i]
						local folder = parentFolder:FindFirstChild(folderName)
						if folder then
							parentFolder = folder
						else
							-- Hedef klasör bulunamadıysa yeni klasör oluştur
							
							if parentFolder:WaitForChild(folderName, 2) then
								folder = parentFolder:FindFirstChild(folderName)
							else
								folder = Instance.new("Folder")
								folder.Name = folderName
								folder.Parent = parentFolder
								parentFolder = folder
							end
							
						end
					end

					-- Adresin sonunda kalan öğeyi hedef klasörün altına taşı
					local itemName = parentNames[#parentNames]
					if not checkDuplicateName(parentFolder, itemName, element) then
						moveToParentFolder(element, parentFolder, itemName)
					end

					-- Adresleri kontrol et ve gerektiğinde güncelle
					local updatedAdress = parentFolder:GetFullName() .. "/" .. itemName
					if adress.Value ~= updatedAdress then
						adress.Value = updatedAdress
					end
				end

				index = index + 1
				wait(delay)
				placeNextElement()
			end
		end

		placeNextElement()
	end
	
	local elementsToPlace = {}

	for name, properties in pairs(data) do
		local element = Instance.new(properties.ClassName)
		element.Name = name

		if element:IsA("NumberValue") then
			element.Value = tonumber(properties.Value)
		elseif element:IsA("StringValue") then
			element.Value = tostring(properties.Value)
		end

		local adress = Instance.new("StringValue", element)
		adress.Name = "Adress"
		adress.Value = properties.Parent

		table.insert(elementsToPlace, element)
	end
	-- Adresleri kontrol et ve gerektiğinde güncelle
	for _, element in ipairs(hddFolder:GetChildren()) do
		local adress = element:FindFirstChild("Adress")
		if adress then
			local parentNames = string.split(adress.Value, "/")
			local parentFolder = hddFolder

			-- Hedef klasörün adresini bulana kadar klasörleri kontrol et
			for i = 2, #parentNames - 1 do
				local folderName = parentNames[i]
				local folder = parentFolder:FindFirstChild(folderName)
				if folder then
					parentFolder = folder
				else
					-- Hedef klasör bulunamadıysa döngüyü sonlandır
					break
				end
			end

			-- Adresin sonunda kalan öğeyi hedef klasörün altına taşı
			local itemName = parentNames[#parentNames]
			if not checkDuplicateName(parentFolder, itemName, element) then
				moveToParentFolder(element, parentFolder, itemName)
			end

			-- Adresleri kontrol et
			local updatedAdress = parentFolder:GetFullName() .. "/" .. itemName
			if adress.Value ~= updatedAdress then
				adress.Value = updatedAdress
			end
		end
	end
	
	placeElementsWithDelay(elementsToPlace, hddFolder, 0.1)
	
	local function deleteDuplicateFolders(parentFolder)
		local folderNames = {} -- Klasör adlarını takip etmek için bir tablo oluştur
		local foldersToDelete = {} -- Silinecek klasörleri takip etmek için bir tablo oluştur

		-- Klasörleri kontrol et ve aynı isimde olanları işaretle
		for _, folder in ipairs(parentFolder:GetChildren()) do
			if folder:IsA("Folder") then
				local folderName = folder.Name
				if folderNames[folderName] then
					table.insert(foldersToDelete, folder)
				else
					folderNames[folderName] = true
				end
			end
		end

		-- Silinecek klasörleri sil
		for _, folder in ipairs(foldersToDelete) do
			folder:Destroy()
		end

		-- İç içe geçmiş klasörlerin içindeki klasörleri kontrol et
		for _, folder in ipairs(parentFolder:GetChildren()) do
			if folder:IsA("Folder") then
				deleteDuplicateFolders(folder)
			end
		end
	end

	-- Klasörleri kontrol et ve silinecek klasörleri belirle
	deleteDuplicateFolders(hddFolder)


	
end

local function savePlayerData(player)
	local hddFolder = player:WaitForChild("HDD")
	if not hddFolder then
		hddFolder = Instance.new("Folder")
		hddFolder.Name = "HDD"
		hddFolder.Parent = player
	end

	local data = {}
	for _, element in ipairs(hddFolder:GetDescendants()) do
		
		local properties = {}
		properties.ClassName = element.ClassName

		local parentText = element.Name
		local x = element

		repeat
			parentText = string.format(x.Parent.Name.."/%s", parentText)
			x = x.Parent
		until x == hddFolder
		
		print(parentText)
		properties.Parent = parentText

		if element:IsA("NumberValue") or element:IsA("StringValue") then
			properties.Value = tostring(element.Value)
		end

		local attributes = element:GetAttributes()
		for propName, propValue in pairs(attributes) do
			properties[propName] = propValue
		end

		data[element.Name] = properties
	end

	local success, errorMessage = pcall(function()
		dataStore:SetAsync(tostring(player.UserId), data)
	end)

	print(success)
	print(errorMessage)

	if not success then
		warn("Veri kaydedilirken bir hata oluştu: " .. errorMessage)
	end
end

game.Players.PlayerAdded:Connect(loadPlayerData)
game.Players.PlayerRemoving:Connect(savePlayerData)
