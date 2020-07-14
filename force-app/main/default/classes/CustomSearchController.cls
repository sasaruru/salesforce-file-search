public class CustomSearchController {
   
    @AuraEnabled
    public static List<Result> searchRecords(String searchText) {

        Integer counter= 0;
        if(searchText.length() < 2){
           return new List<Result>(); 
        }
        // コンテンツID取得
        String query = 'find \'' + searchText + '\' in all fields returning ContentVersion(Id,Title,ContentDocumentId,ContentUrl)';
        System.Debug(query);
        List<List <sObject>> sobList =  search.query(query);
        // ドキュメントID取得
        List<ContentVersion> cList = (List<ContentVersion>)sobList[0];
        Set<String> contentVersionIds = new Set<String>();
        for (ContentVersion cv : cList){
            System.Debug(cv);
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

        // デモ版は取引先責任者固定.
        // phase1で画面から対象オブジェクトの取得
        // phase2で取得項目の選択?
        String tbl = 'Contact';
        String q = 'SELECT Id, Name FROM ' + tbl + ' WHERE Id in :linkedEntityIds';
        List<SObject> objList = Database.query(q);
        List<Result> results = new List<Result>();
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
        public String link;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String contentLink;
        @AuraEnabled
        public String documentId;
        
        public Result(String objId, String objName,List<ContentDocumentLink> contentDocumentLinks,List<ContentVersion> contentVersions) {
            id = objId;
            name = objName;
            link = '/'+objId;
            documentId='';
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinks){
                if(id.equals(contentDocumentLink.LinkedEntityId)){
                    documentId = contentDocumentLink.ContentDocumentId;
                    contentLink = '/' + documentId;
                    break;
                }
            }
            for (ContentVersion contentVersion :contentVersions){
                if(documentId.equals(contentVersion.ContentDocumentId)){
                    title = contentVersion.Title;
                   // contentLink = contentVersion.ContentUrl;
                }
            }
        }
    }
}
