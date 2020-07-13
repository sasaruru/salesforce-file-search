public class CustomSearchController {
   
    @AuraEnabled
    public static List<Result> searchRecords(String searchText) {

        Integer counter= 0;
        if(searchText.length() < 2){
           return new List<Result>(); 
        }
        // コンテンツID取得
        String query = 'find \'' + searchText + '*\' in all fields returning ContentVersion(Id,Title,ContentDocumentId)';
        System.Debug(query);
        List<List <sObject>> sobList =  search.query(query);
        // ドキュメントID取得
        List<ContentVersion> cList = (List<ContentVersion>)sobList[0];
        Set<String> contentVersionIds = new Set<String>();
        for (ContentVersion cv : cList){
            contentVersionIds.add(cv.ContentDocumentId);
        }
        System.Debug(contentVersionIds);

        // ドキュメントリンク取得
        List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId in :contentVersionIds];
        Set<String> linkedEntityIds = new Set<String>();
        for (ContentDocumentLink cdLink : contentDocumentLinks){
            linkedEntityIds.add(cdLink.LinkedEntityId);
        }
        System.Debug(linkedEntityIds);

        List<Contact> objList = [SELECT Id, Name FROM Contact WHERE Id in :linkedEntityIds];
        List<Result> results = new List<Result>();
        for (Contact c : objList){
            results.add(new Result(c.Id, c.Name, contentDocumentLinks, cList));
        }
        return results;

    }
    public class Result {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String link;
        @AuraEnabled
        public String title;
        
        public Result(String objId, String objName,List<ContentDocumentLink> contentDocumentLinks,List<ContentVersion> contentVersions) {
            id = objId;
            name = objName;
            link = '/'+objId;
            String documentId = '';
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinks){
                if(id.equals(contentDocumentLink.LinkedEntityId)){
                    documentId = contentDocumentLink.ContentDocumentId;
                    break;
                }
            }
            for (ContentVersion contentVersion :contentVersions){
                if(documentId.equals(contentVersion.ContentDocumentId)){
                    title = contentVersion.Title;
                }
            }
        }
    }
}
