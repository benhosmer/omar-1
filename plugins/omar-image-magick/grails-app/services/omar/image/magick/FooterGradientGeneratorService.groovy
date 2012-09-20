package omar.image.magick

class FooterGradientGeneratorService 
{
	def DEBUG = false
	def grailsApplication

	def command
	def serviceMethod(def gradientColorTop, def gradientColorBottom, def gradientHeight)
	{
		def date = new Date().getTime()
		def tempFilesLocation = grailsApplication.config.export.workDir + "/"

		command = [
				"convert", 
				"-size", 
				"1x${gradientHeight}", 
				"gradient: #${gradientColorTop}-#${gradientColorBottom}", 
				"${tempFilesLocation}${date}gradient.png"
		]
		executeCommand(command)

		return "${tempFilesLocation}${date}gradient.png"
	}

	def executeCommand(def executableCommand)
	{
		def script = executableCommand.execute()
		script.waitFor()
		return script.text
	}
}
