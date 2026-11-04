/*
 * This file is part of the Cfx project - https://cfx.re/
 *
 * See LICENSE in the root of the source tree for information
 * regarding licensing.
 */

#include "StdInc.h"
#include "CustomPlateRegistry.h"

#include <tinyxml2.h>
#include <VFSManager.h>
#include <Resource.h>
#include <ResourceMetaDataComponent.h>
#include <CoreConsole.h>
#include <ScriptEngine.h>
#include <fxScripting.h>

extern void SetCustomPlatePatternInternal(int index, const std::string& pattern);
extern void RemoveCustomPlatePatternInternal(int index);

CustomPlateRegistry* CustomPlateRegistry::GetInstance()
{
	static CustomPlateRegistry s_instance;
	return &s_instance;
}

int CustomPlateRegistry::RegisterPlate(const CustomPlateData& plate)
{
	std::unique_lock<std::shared_mutex> lock(m_mutex);

	CustomPlateData entry = plate;

	if (entry.index < 0)
	{
		while (m_platesByIndex.find(m_nextAutoIndex) != m_platesByIndex.end())
		{
			++m_nextAutoIndex;
		}

		if (m_nextAutoIndex > kMaxCustomPlateIndex)
		{
			trace("CustomPlateRegistry: Exceeded maximum allowed plate index (%d)\n", kMaxCustomPlateIndex);
			return -1;
		}

		entry.index = m_nextAutoIndex++;
	}
	else if (entry.index < kFirstCustomPlateIndex)
	{
		trace("CustomPlateRegistry: Slot index %d is reserved for vanilla plates (0-%d)\n", entry.index, kFirstCustomPlateIndex - 1);
		return -1;
	}

	if (entry.normalDict.empty())
	{
		entry.normalDict = entry.diffuseDict;
	}

	int assignedIndex = entry.index;
	m_platesByIndex[assignedIndex] = entry;

	if (!entry.name.empty())
	{
		m_indexByName[entry.name] = assignedIndex;
	}

	if (!entry.pattern.empty())
	{
		SetCustomPlatePatternInternal(assignedIndex, entry.pattern);
	}

	trace("CustomPlateRegistry: Registered plate '%s' at slot index %d [diffuse: %s/%s, normal: %s/%s]\n",
		entry.name.c_str(), assignedIndex,
		entry.diffuseDict.c_str(), entry.diffuseTex.c_str(),
		entry.normalDict.c_str(), entry.normalTex.c_str());

	return assignedIndex;
}

bool CustomPlateRegistry::UnregisterPlate(int index)
{
	std::unique_lock<std::shared_mutex> lock(m_mutex);

	auto it = m_platesByIndex.find(index);
	if (it == m_platesByIndex.end())
	{
		return false;
	}

	if (!it->second.name.empty())
	{
		m_indexByName.erase(it->second.name);
	}

	RemoveCustomPlatePatternInternal(index);
	m_platesByIndex.erase(it);

	return true;
}

void CustomPlateRegistry::UnregisterPlatesForResource(const std::string& resourceName)
{
	std::unique_lock<std::shared_mutex> lock(m_mutex);

	for (auto it = m_platesByIndex.begin(); it != m_platesByIndex.end(); )
	{
		if (it->second.resourceName == resourceName)
		{
			if (!it->second.name.empty())
			{
				m_indexByName.erase(it->second.name);
			}

			RemoveCustomPlatePatternInternal(it->first);
			it = m_platesByIndex.erase(it);
		}
		else
		{
			++it;
		}
	}
}

const CustomPlateData* CustomPlateRegistry::GetPlate(int index) const
{
	std::shared_lock<std::shared_mutex> lock(m_mutex);

	auto it = m_platesByIndex.find(index);
	if (it != m_platesByIndex.end())
	{
		return &it->second;
	}

	return nullptr;
}

const CustomPlateData* CustomPlateRegistry::FindPlateByName(const std::string& name) const
{
	std::shared_lock<std::shared_mutex> lock(m_mutex);

	auto itName = m_indexByName.find(name);
	if (itName != m_indexByName.end())
	{
		auto itPlate = m_platesByIndex.find(itName->second);
		if (itPlate != m_platesByIndex.end())
		{
			return &itPlate->second;
		}
	}

	return nullptr;
}

int CustomPlateRegistry::GetCount() const
{
	std::shared_lock<std::shared_mutex> lock(m_mutex);
	return static_cast<int>(m_platesByIndex.size());
}

bool CustomPlateRegistry::IsValidCustomIndex(int index) const
{
	std::shared_lock<std::shared_mutex> lock(m_mutex);
	return m_platesByIndex.find(index) != m_platesByIndex.end();
}

void CustomPlateRegistry::Clear()
{
	std::unique_lock<std::shared_mutex> lock(m_mutex);
	for (const auto& [idx, data] : m_platesByIndex)
	{
		RemoveCustomPlatePatternInternal(idx);
	}
	m_platesByIndex.clear();
	m_indexByName.clear();
	m_nextAutoIndex = kFirstCustomPlateIndex;
}

static std::string GetElementTextSafe(const tinyxml2::XMLElement* element)
{
	if (!element)
	{
		return "";
	}

	const char* text = element->GetText();
	return text ? text : "";
}

int CustomPlateRegistry::LoadPlatesFromXml(const std::string& xmlContent, const std::string& resourceName)
{
	tinyxml2::XMLDocument doc;
	tinyxml2::XMLError err = doc.Parse(xmlContent.c_str(), xmlContent.size());
	if (err != tinyxml2::XML_SUCCESS)
	{
		trace("CustomPlateRegistry: Failed to parse XML plate file from resource %s (error %d)\n", resourceName.c_str(), err);
		return 0;
	}

	const tinyxml2::XMLElement* root = doc.RootElement();
	if (!root)
	{
		return 0;
	}

	const tinyxml2::XMLElement* platesContainer = root->FirstChildElement("plates");
	if (!platesContainer)
	{
		platesContainer = root->FirstChildElement("VehiclePlates");
	}
	if (!platesContainer)
	{
		platesContainer = root;
	}

	int registeredCount = 0;

	for (const tinyxml2::XMLElement* item = platesContainer->FirstChildElement("Item"); item != nullptr; item = item->NextSiblingElement("Item"))
	{
		CustomPlateData plate;
		plate.resourceName = resourceName;

		plate.name = GetElementTextSafe(item->FirstChildElement("name"));

		// Diffuse dict
		plate.diffuseDict = GetElementTextSafe(item->FirstChildElement("diffuseDict"));
		if (plate.diffuseDict.empty())
		{
			plate.diffuseDict = GetElementTextSafe(item->FirstChildElement("diffuseTexture"));
		}

		// Diffuse texture name
		plate.diffuseTex = GetElementTextSafe(item->FirstChildElement("diffuseTex"));
		if (plate.diffuseTex.empty())
		{
			plate.diffuseTex = GetElementTextSafe(item->FirstChildElement("fileName"));
		}

		// Normal dict
		plate.normalDict = GetElementTextSafe(item->FirstChildElement("normalDict"));
		if (plate.normalDict.empty())
		{
			plate.normalDict = plate.diffuseDict;
		}

		// Normal texture name
		plate.normalTex = GetElementTextSafe(item->FirstChildElement("normalTex"));
		if (plate.normalTex.empty())
		{
			plate.normalTex = GetElementTextSafe(item->FirstChildElement("normalName"));
		}

		// Pattern
		plate.pattern = GetElementTextSafe(item->FirstChildElement("pattern"));

		// Text color
		const tinyxml2::XMLElement* colorElem = item->FirstChildElement("textColor");
		if (colorElem)
		{
			const char* colorText = colorElem->GetText();
			if (colorText)
			{
				plate.textColor = std::strtoul(colorText, nullptr, 0);
			}
		}

		// Explicit index
		const tinyxml2::XMLElement* indexElem = item->FirstChildElement("index");
		if (indexElem)
		{
			plate.index = indexElem->IntText(-1);
		}

		if (plate.diffuseTex.empty() && !plate.diffuseDict.empty())
		{
			plate.diffuseTex = plate.diffuseDict;
		}

		if (!plate.diffuseTex.empty())
		{
			if (plate.diffuseDict.empty())
			{
				plate.diffuseDict = plate.diffuseTex;
			}

			if (RegisterPlate(plate) >= 0)
			{
				++registeredCount;
			}
		}
	}

	return registeredCount;
}

static InitFunction initFunction([]()
{
	fx::Resource::OnInitializeInstance.Connect([](fx::Resource* resource)
	{
		resource->OnStart.Connect([resource]()
		{
			fwRefContainer<fx::ResourceMetaDataComponent> metaData = resource->GetComponent<fx::ResourceMetaDataComponent>();
			if (!metaData.GetRef())
			{
				return;
			}

			std::string resourcePath = resource->GetPath();
			std::string resourceName = resource->GetName();

			std::vector<std::string> plateFiles;

			// 1. vehicle_plate_file 'filename'
			for (const auto& entry : metaData->GetEntries("vehicle_plate_file"))
			{
				plateFiles.push_back(entry.second);
			}

			// 2. data_file 'VEHICLE_PLATE_FILE' 'filename'
			auto dataFileEntries = metaData->GetEntries("data_file");
			auto dataFileExtraEntries = metaData->GetEntries("data_file_extra");

			auto itData = dataFileEntries.begin();
			auto itExtra = dataFileExtraEntries.begin();

			while (itData != dataFileEntries.end() && itExtra != dataFileExtraEntries.end())
			{
				if (itData->second == "VEHICLE_PLATE_FILE")
				{
					plateFiles.push_back(itExtra->second);
				}
				++itData;
				++itExtra;
			}

			for (const auto& relativePath : plateFiles)
			{
				std::string cleanPath = relativePath;
				if (!cleanPath.empty() && cleanPath.front() == '"' && cleanPath.back() == '"')
				{
					cleanPath = cleanPath.substr(1, cleanPath.length() - 2);
				}

				std::string fullPath = resourcePath + "/" + cleanPath;
				fwRefContainer<vfs::Stream> stream = vfs::OpenRead(fullPath);
				if (!stream.GetRef())
				{
					// Try without slash prefix or directly
					fullPath = cleanPath;
					stream = vfs::OpenRead(fullPath);
				}

				if (stream.GetRef())
				{
					std::vector<uint8_t> buffer(stream->GetLength());
					stream->Read(buffer.data(), buffer.size());
					std::string content(buffer.begin(), buffer.end());

					CustomPlateRegistry::GetInstance()->LoadPlatesFromXml(content, resourceName);
				}
				else
				{
					trace("CustomPlateRegistry: Could not open plate file '%s' for resource '%s'\n", cleanPath.c_str(), resourceName.c_str());
				}
			}
		});

		resource->OnStop.Connect([resource]()
		{
			CustomPlateRegistry::GetInstance()->UnregisterPlatesForResource(resource->GetName());
		});
	});

	// Register script helper natives
	fx::ScriptEngine::RegisterNativeHandler("ADD_VEHICLE_NUMBER_PLATE_STYLE", [](fx::ScriptContext& context)
	{
		const char* name = context.GetArgument<const char*>(0);
		const char* diffuseDict = context.GetArgument<const char*>(1);
		const char* diffuseTex = context.GetArgument<const char*>(2);
		const char* normalDict = context.GetArgument<const char*>(3);
		const char* normalTex = context.GetArgument<const char*>(4);
		const char* pattern = context.GetArgument<const char*>(5);

		CustomPlateData data;
		data.name = name ? name : "";
		data.diffuseDict = diffuseDict ? diffuseDict : "";
		data.diffuseTex = diffuseTex ? diffuseTex : "";
		data.normalDict = normalDict ? normalDict : "";
		data.normalTex = normalTex ? normalTex : "";
		data.pattern = pattern ? pattern : "";

		fx::OMPtr<IScriptRuntime> runtime;
		if (FX_SUCCEEDED(fx::GetCurrentScriptRuntime(&runtime)))
		{
			auto resource = static_cast<fx::Resource*>(runtime->GetParentObject());
			if (resource)
			{
				data.resourceName = resource->GetName();
			}
		}

		int result = CustomPlateRegistry::GetInstance()->RegisterPlate(data);
		context.SetResult<int>(result);
	});

	fx::ScriptEngine::RegisterNativeHandler("GET_VEHICLE_NUMBER_PLATE_INDEX_BY_NAME", [](fx::ScriptContext& context)
	{
		const char* name = context.GetArgument<const char*>(0);
		if (!name)
		{
			context.SetResult<int>(-1);
			return;
		}

		const auto* plate = CustomPlateRegistry::GetInstance()->FindPlateByName(name);
		context.SetResult<int>(plate ? plate->index : -1);
	});

	fx::ScriptEngine::RegisterNativeHandler("GET_VEHICLE_NUMBER_PLATE_NAME", [](fx::ScriptContext& context)
	{
		int index = context.GetArgument<int>(0);
		const auto* plate = CustomPlateRegistry::GetInstance()->GetPlate(index);
		context.SetResult<const char*>(plate ? plate->name.c_str() : "");
	});
});

