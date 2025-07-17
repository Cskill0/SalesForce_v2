trigger seguimientoTrigger on Seguimiento__c (before insert, before update, after insert, after update) {
	Set<Id> contactoIds = new Set<Id>();

	for (Seguimiento__c s : Trigger.new) {
		if (s.Contacto_c__c != null) {
			contactoIds.add(s.Contacto_c__c);
		}
	}

	if (!contactoIds.isEmpty() && Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
		Map<Id, Integer> pendientesBD = new Map<Id, Integer>();
		for (AggregateResult ar : [
			SELECT Contacto_c__c contactId, COUNT(Id) total
			FROM Seguimiento__c
			WHERE Contacto_c__c IN :contactoIds AND Etapa__c = 'Pendiente'
			GROUP BY Contacto_c__c
		]) {
			pendientesBD.put((Id) ar.get('contactId'), (Integer) ar.get('total'));
		}

		Map<Id, Integer> nuevosPendientes = new Map<Id, Integer>();
		for (Seguimiento__c s : Trigger.new) {
			if (s.Contacto_c__c != null && s.Etapa__c == 'Pendiente') {
				Id contactoId = s.Contacto_c__c;

				if (Trigger.isUpdate) {
					Seguimiento__c oldS = Trigger.oldMap.get(s.Id);
					if (oldS != null && oldS.Etapa__c == 'Pendiente') continue;
				}

				Integer yaEnTrigger = nuevosPendientes.get(contactoId);
				nuevosPendientes.put(contactoId, (yaEnTrigger != null ? yaEnTrigger : 0) + 1);
			}
		}

		for (Seguimiento__c s : Trigger.new) {
			if (s.Contacto_c__c != null && s.Etapa__c == 'Pendiente') {
				Integer enBD = pendientesBD.get(s.Contacto_c__c) != null ? pendientesBD.get(s.Contacto_c__c) : 0;
				Integer enTrigger = nuevosPendientes.get(s.Contacto_c__c) != null ? nuevosPendientes.get(s.Contacto_c__c) : 0;

				if ((enBD + enTrigger) > 5) {
					s.addError('No se puede tener mas de 5 seguimientos pendientes para este contacto.');
				}
			}
		}
	}

	if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
		for (Seguimiento__c s : Trigger.new) {
			Seguimiento__c oldS = Trigger.isUpdate ? Trigger.oldMap.get(s.Id) : null;

			Boolean ubicacionNueva = (Trigger.isInsert && s.Ubicacion__c != null) ||
									 (Trigger.isUpdate && s.Ubicacion__c != null && s.Ubicacion__c != oldS.Ubicacion__c);

			if (ubicacionNueva) {
				WeatherServicio.fetchWeather(s.Id, s.Ubicacion__c);
			}
		}
	}
}
