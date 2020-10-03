public class CustomSearchController {

    @AuraEnabled
    public static Map<ID, SObject> getObjectInfo(String targetObject ,String targetColumns, List<String> ids ){
        // クエリ生成
        String q = 'SELECT Id, Name,' + targetColumns + ' FROM ' + targetObject + ' WHERE Id in :ids';
        List<SObject> sList = Database.query(q);
        Map<Id, SObject> result = new Map<Id, SObject>(Database.query(q));
        return result;
    }

    @AuraEnabled
    public static List<Map<String, String>> getObjSelectOptions(List<String> objs){
        // mapの中身は
        // key : label, value
        // value: オブジェクトのAPI, ラベル名
        List<Map<String, String>> result = new List<Map<String, String>>();

        for(String obj : objs){
            Map<String, String> option = new Map<String, String>();
            option.put('value', obj);

            Map<String, sObjectType> sObjTypeMap = Schema.getGlobalDescribe();
            sObjectType sObjType = sObjTypeMap.get(obj);
            option.put('label', sObjType.getDescribe().getLabel());

            result.add(option);
        }
        return result;
    }
   
    @AuraEnabled
    public static List<Result> searchRecords(String searchText, String targetObject, String sortValue, Integer limits) {
        List<Result> results = new List<Result>();
        Integer counter= 0;
        if(searchText.length() < 2){
           return results; 
        }
        // ------------------------------
        //  SQSLによるコンテンツID取得
        // ------------------------------
        String query = 'find \'' + createSeachText(searchText) + '\' in all fields returning ContentVersion(Id,Title,ContentDocumentId,FileExtension,SystemModstamp ORDER BY SystemModstamp ' + sortValue + ' LIMIT ' + limits.format() +')';
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
        // 画面表示は検索されたファイル分のため取得したContentVersion事にオブジェクト作成
        for (ContentVersion contentVersion : cList){
            Result result = createResult(contentVersion, contentDocumentLinks, objList);
            if(result != null){
                results.add(result);
            }
        }
        return results;
    }
    // 間にスペースあればANDでつなぐ
    private static String createSeachText(String baseSearchText){
        // 全角スペースを半角スペースへ変換し、Trim
        baseSearchText = baseSearchText.replace('　',' ').trim();
        // 半角スペースをAND変換
        return baseSearchText.replace(' ',' AND ');
    }

    private static Result createResult(ContentVersion contentVersion,List<ContentDocumentLink> contentDocumentLinks,List<SObject> objLists){
        String targetRecordId = '';
        String documentId = contentVersion.ContentDocumentId;
        // breakするとloop全体が止まってしまう仕様らしく、
        // 仕方がないがネスト対応
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks){
            if(documentId.equals(contentDocumentLink.ContentDocumentId)){
                targetRecordId = contentDocumentLink.LinkedEntityId;
                for (SObject obj :objLists){
                    if(targetRecordId.equals((string)obj.get('Id'))){
                        return new Result(obj, contentVersion);
                    }
                }               
            }
        }        
        return null;
    }
    @TestVisible public class Result {
        @AuraEnabled
        public String targetId;
        @AuraEnabled
        public String targetName;
        @AuraEnabled
        public String targetLink;
        @AuraEnabled
        public String documentTitle;
        @AuraEnabled
        public String documentLink;
        @AuraEnabled
        public String documentId;
        @AuraEnabled
        public String documentExtension;
        @AuraEnabled
        public String lastUpdate;
        
        public Result(SObject obj, ContentVersion contentVersion) {
            targetId = (string)obj.get('Id');
            targetLink = '/' + (string)obj.get('Id');
            targetName = (string)obj.get('Name');

            documentId = contentVersion.ContentDocumentId;
            documentLink = '/' + contentVersion.ContentDocumentId;
            documentTitle = contentVersion.Title;
            documentExtension = contentVersion.FileExtension;
            lastUpdate = contentVersion.SystemModstamp.format('yyyy/MM/dd HH:mm','Asia/Tokyo');
        }
    }
}
