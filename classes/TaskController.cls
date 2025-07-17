public with sharing class TaskController {
	@AuraEnabled(cacheable=true)
	public static Map<String, Integer> getTaskStats(Id contactId) {
		Integer total = [SELECT COUNT() FROM Task WHERE WhoId = :contactId];
		Integer completed = [SELECT COUNT() FROM Task WHERE WhoId = :contactId AND Status = 'Completed'];
		
		Map<String, Integer> stats = new Map<String, Integer>();
		stats.put('total', total);
		stats.put('completed', completed);
		return stats;
	}
}