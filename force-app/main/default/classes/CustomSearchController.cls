public class CustomSearchController {
   
    @AuraEnabled
    public static List<Result> searchRecords(String searchText, String targetObject) {
        List<Result> results = new List<Result>();
        Integer counter= 0;
        if(searchText.length() < 2){
           return results; 
        }
        // ------------------------------
        //  SQSLによるコンテンツID取得
        // ------------------------------
        String query = 'find \'' + searchText + '\' in all fields returning ContentVersion(Id,Title,ContentDocumentId,ContentUrl,SystemModstamp)';
        System.Debug(query);
        List<List <sObject>> sobList =  search.query(query);
        // ドキュメントID取得
        List<ContentVersion> cList = (List<ContentVersion>)sobList[0];
        if(cList.size() == 0){
            return results;
        }
        // ----------------------------------------------------------
        //  contentVersionIdからcontentDocumentLinksのentityId取得
        // ----------------------------------------------------------    
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
        // ----------------------------------------------------------
        //  LinkedEntityIdから対象オブジェクトレコード取得
        // ----------------------------------------------------------    
        String q = 'SELECT Id, Name FROM ' + targetObject + ' WHERE Id in :linkedEntityIds';
        List<SObject> objList = Database.query(q);
        for (SObject obj : objList){
            results.add(new Result((String)obj.get('Id'), (String)obj.get('Name'), contentDocumentLinks, cList));
        }
        return results;

    }
    public class Result {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String objectLink;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String documentLink;
        @AuraEnabled
        public String documentId;
        @AuraEnabled
        public String lastUpdate;
        
        public Result(String objId, String objName,List<ContentDocumentLink> contentDocumentLinks,List<ContentVersion> contentVersions) {
            id = objId;
            name = objName;
            objectLink = '/'+objId;
            documentId='';
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinks){
                if(id.equals(contentDocumentLink.LinkedEntityId)){
                    documentId = contentDocumentLink.ContentDocumentId;
                    documentLink = '/' + documentId;
                    break;
                }
            }
            for (ContentVersion contentVersion :contentVersions){
                if(documentId.equals(contentVersion.ContentDocumentId)){
                    title = contentVersion.Title;
                    lastUpdate = contentVersion.SystemModstamp.format('yyyy/MM/dd HH:mm','Asia/Tokyo');
                }
            }
        }
    }
}
