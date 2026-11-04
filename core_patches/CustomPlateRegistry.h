/*
 * This file is part of the Cfx project - https://cfx.re/
 *
 * See LICENSE in the root of the source tree for information
 * regarding licensing.
 */

#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <shared_mutex>
#include <cstdint>
#include <optional>

struct CustomPlateData
{
	int index = -1;
	std::string name;
	std::string diffuseDict;
	std::string diffuseTex;
	std::string normalDict;
	std::string normalTex;
	std::string pattern;
	uint32_t textColor = 0xFFFFFFFF;
	std::string resourceName;
};

class CustomPlateRegistry
{
public:
	static constexpr int kFirstCustomPlateIndex = 13;
	static constexpr int kMaxCustomPlateIndex = 32767;

	static CustomPlateRegistry* GetInstance();

	// Registers a custom plate. If plate.index < 0, an available slot is automatically assigned.
	// Returns the assigned slot index (>= 13), or -1 on failure.
	int RegisterPlate(const CustomPlateData& plate);

	// Unregisters a specific custom plate slot index.
	bool UnregisterPlate(int index);

	// Unregisters all plates that were registered by a specific resource.
	void UnregisterPlatesForResource(const std::string& resourceName);

	// Retrieves plate data by slot index.
	const CustomPlateData* GetPlate(int index) const;

	// Finds a plate by its string identifier/name.
	const CustomPlateData* FindPlateByName(const std::string& name) const;

	// Returns the total number of registered custom plates.
	int GetCount() const;

	// Checks if an index is a registered custom plate slot (>= 13).
	bool IsValidCustomIndex(int index) const;

	// Parses XML data from a VEHICLE_PLATE_FILE (plates.meta) and registers each plate.
	// Returns the number of plates registered.
	int LoadPlatesFromXml(const std::string& xmlContent, const std::string& resourceName);

	// Clears all custom plates.
	void Clear();

private:
	CustomPlateRegistry() = default;
	~CustomPlateRegistry() = default;

	mutable std::shared_mutex m_mutex;
	std::unordered_map<int, CustomPlateData> m_platesByIndex;
	std::unordered_map<std::string, int> m_indexByName;
	int m_nextAutoIndex = kFirstCustomPlateIndex;
};

