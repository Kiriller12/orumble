local models = {
	--Ramps
	--{"FunBoxRamp1", "MatRamps", 1899},
	--{"FunBoxRamp2", "MatRamps", 1909},
	--{"FunBoxRamp4", "MatRamps", 1910},
	--{"FunBoxTop1", "MatRamps", 1912},
	
	--Platforms
	{"CarDarts", "CarDarts", 1913},
}

addEventHandler("onClientResourceStart", resourceRoot,
function()
	for _, mdl in ipairs(models) do
		local col = engineLoadCOL("models/" .. mdl[1] .. ".col")
		engineReplaceCOL(col, mdl[3])

		local txd = engineLoadTXD("models/" .. mdl[2] .. ".txd")
		engineImportTXD(txd, mdl[3])

		local dff = engineLoadDFF("models/" .. mdl[1] .. ".dff")
		engineReplaceModel(dff, mdl[3])
		
		engineSetModelLODDistance(mdl[3], 300)
	end
end
)