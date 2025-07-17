public with sharing class SeguimientoControlador {

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getSeguimientoStats(Id contactoId) {
		Map<String, Object> result = new Map<String, Object>();

		//Total de seguimientos
		Integer total = [SELECT COUNT() FROM Seguimiento__c WHERE Contacto_c__c = :contactoId];
		result.put('total', total);

		Integer completado = [SELECT COUNT() FROM Seguimiento__c WHERE Contacto_c__c = :contactoId AND Etapa__c = 'Completado'];
		result.put('completado', completado);

		Integer enProceso = [SELECT COUNT() FROM Seguimiento__c WHERE Contacto_c__c = :contactoId AND Etapa__c = 'En Proceso'];
		result.put('enProceso', enProceso);

		Integer pendiente = [SELECT COUNT() FROM Seguimiento__c WHERE Contacto_c__c = :contactoId AND Etapa__c = 'Pendiente'];
		result.put('pendiente', pendiente);

		List<Seguimiento__c> ultimos = [
			SELECT Name, CreatedDate, Clima_Actual__c
			FROM Seguimiento__c
			WHERE Contacto_c__c = :contactoId
			ORDER BY CreatedDate DESC
			LIMIT 1
		];

		if (!ultimos.isEmpty()) {
			result.put('ultimoNombre', ultimos[0].Name);
			result.put('ultimoClima', ultimos[0].Clima_Actual__c);
		} else {
			result.put('ultimoNombre', 'Sin seguimientos');
			result.put('ultimoClima', 'Sin clima disponible');
		}

		return result;
	}

	@AuraEnabled
	public static List<Seguimiento__c> obtenerSeguimientos(Id contactoId) {
		return [
			SELECT Name, CreatedDate, Clima_actual__c
			FROM Seguimiento__c
			WHERE Contacto_c__c = :contactoId
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
	}



	@AuraEnabled
	public static Integer contarPorEtapa(Id contactoId, String etapa) {
		return [
			SELECT COUNT()
			FROM Seguimiento__c
			WHERE Contacto_c__c = :contactoId AND Etapa__c = :etapa
		];
	}

	@AuraEnabled
	public static void actualizarClima(Id seguimientoId) {
		Seguimiento__c seg = [
			SELECT Id, Ubicacion__c
			FROM Seguimiento__c
			WHERE Id = :seguimientoId
			LIMIT 1
		];

		String ciudad = seg.Ubicacion__c;

		if (String.isNotBlank(ciudad)) {
			WeatherServicio.fetchWeather(seg.Id, ciudad);
		} else {
			throw new AuraHandledException('No se ha definido una ubicacion para este seguimiento.');
		}
	}


}
