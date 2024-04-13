#[=======================================================================[.rst:
Spriggit
--------

Deserialize BGS Data Files from Spriggit format

Usage:

.. code-block:: cmake

  Spriggit_Deserialize(<target> INPUT <input_path> OUTPUT <output_path>
                       [PACKAGE <nuget_package>] [COMPONENT] <component>
                       [EXCLUDE_FROM_ALL])

#]=======================================================================]

function(Spriggit_Deserialize SPRIGGIT_TARGET)
	set(options EXCLUDE_FROM_ALL)
	set(oneValueArgs INPUT OUTPUT PACKAGE COMPONENT)
	set(multiValueArgs)
	cmake_parse_arguments(SPRIGGIT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	file(DOWNLOAD
		https://github.com/Mutagen-Modding/Spriggit/releases/download/0.18/SpriggitCLI.zip
		"${CMAKE_CURRENT_BINARY_DIR}/download/SpriggitCLI.zip"
		EXPECTED_HASH SHA512=602e23fb8543e9eaa233d9a4d6a095ba1f0ce51b859a95320535b4651bf386cb187caf4208ac4bfaff5d14b3f995437112e43eb4cf296cf814a164d4c822bef7
	)

	file(ARCHIVE_EXTRACT
		INPUT "${CMAKE_CURRENT_BINARY_DIR}/download/SpriggitCLI.zip"
		DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/tools/Spriggit"
	)

	set(SPRIGGIT_EXECUTABLE "${CMAKE_CURRENT_BINARY_DIR}/tools/Spriggit/Spriggit.CLI.exe")

	file(GLOB_RECURSE SPRIGGIT_DEPENDS
		LIST_DIRECTORIES false
		CONFIGURE_DEPENDS
		"${SPRIGGIT_INPUT}/*"
	)

	set(SPRIGGIT_ARGS
		deserialize
		--InputPath "${SPRIGGIT_INPUT}"
		--OutputPath "${SPRIGGIT_OUTPUT}"
	)

	if(SPRIGGIT_PACKAGE)
		list(APPEND SPRIGGIT_ARGS --PackageName "${SPRIGGIT_PACKAGE}")
	endif()

	add_custom_command(
		OUTPUT "${SPRIGGIT_OUTPUT}"
		COMMAND ${SPRIGGIT_EXECUTABLE} ${SPRIGGIT_ARGS}
		DEPENDS ${SPRIGGIT_DEPENDS}
		COMMAND_EXPAND_LISTS
	)

	add_custom_target(
		"${SPRIGGIT_TARGET}"
		ALL
		DEPENDS "${SPRIGGIT_OUTPUT}"
	)

	if(SPRIGGIT_COMPONENT)
		if(SPRIGGIT_EXCLUDE_FROM_ALL)
			install(
				FILES ${SPRIGGIT_OUTPUT}
				DESTINATION "."
				COMPONENT ${SPRIGGIT_COMPONENT}
				EXCLUDE_FROM_ALL
			)
		else()
			install(
				FILES ${SPRIGGIT_OUTPUT}
				DESTINATION "."
				COMPONENT ${SPRIGGIT_COMPONENT}
			)
		endif()
	endif()

endfunction()
