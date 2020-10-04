@isTest
public class CustomSearchControllerTest {

    // 1アカウント1コンテンツがヒット
    @isTest static void testOneAccountOneContent(){
        Test.startTest();
        // SQSL結果を設定
        Id docId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test Document'].Id;
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = docId;
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Test','Account','desc', 10);
        System.assertEquals(1, results.size());
        System.assertEquals('Test Account', results[0].targetName);
        System.assertEquals('Test Document', results[0].documentTitle);
        Test.stopTest();
    }

    // 1アカウント2ドキュメントがヒット
    @isTest static void testOneAccountTwoContent(){
        Test.startTest();
        // 追加のファイルを生成
        Account account = [SELECT Id, Name FROM Account WHERE Name = 'Test Account'];
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Sample Document';
        cv.PathOnClient = 'SampleDocument.pdf';
        cv.VersionData = Blob.valueOf('Sample Content');
        cv.IsMajorVersion = true;
        Insert cv;
        //Get Content Documents
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = account.Id;
        cdl.ContentDocumentId = con.ContentDocumentId;
        cdl.shareType = 'V';
        Insert cdl;

        // SQSL結果を設定
        Id docId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test Document'].Id;
        Id docId2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Sample Document'].Id;
        Id [] fixedSearchResults= new Id[2];
        fixedSearchResults[0] = docId;
        fixedSearchResults[1] = docId2;
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Document','Account', 'asc', 2);
        System.assertEquals(2, results.size());
        for (CustomSearchController.Result result : results){
            System.assert('Test Document'.equals(result.documentTitle) || 'Sample Document'.equals(result.documentTitle));
            System.assertEquals('Test Account', result.targetName);
        }
        Test.stopTest();
    }

    // 2アカウントがヒット
    @isTest static void testTwoAccountTwoContent(){
        Test.startTest();
        // テストデータ（親オブジェクトとファイルのペア）作成
        createTestData();

        List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test Document'];
        Id [] fixedSearchResults= new Id[2];
        for(Integer i=0 ; i < contentVersionList.size() ; i++){
            fixedSearchResults[i] = contentVersionList[i].Id;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Test','Account', 'desc', 500);
        System.assertEquals(2, results.size());
        for (CustomSearchController.Result result : results){
            System.assert('Test Account'.equals(result.targetName) || 'Test Account2'.equals(result.targetName));
            System.assertEquals('Test Document', result.documentTitle);
        }
        Test.stopTest();
    }

    // ヒットなし
    @isTest static void testNoContent(){
        Test.startTest();
        // SQSL結果を設定
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Test','Account', 'asc', 100);
        System.assertEquals(0, results.size());
        Test.stopTest();
    }

    // 文字数が少ないことによる検索失敗
    @isTest static void testMinKeyword(){
        Test.startTest();
        // SQSL結果を設定
        Id docId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test Document'].Id;
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = docId;
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('T','Account','asc',100);
        System.assertEquals(0, results.size());
        Test.stopTest();
    }

    // ファイルは検索されたが、親オブジェクトに関連づいていないので結果なし
    @isTest static void testNoParent(){
        Test.startTest();
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Sample Document';
        cv.PathOnClient = 'SampleDocument.pdf';
        cv.VersionData = Blob.valueOf('Sample Content');
        cv.IsMajorVersion = true;
        Insert cv;
        //Get Content Documents
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = con.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Sample','Account', 'asc', 100);
        System.assertEquals(0, results.size());
        Test.stopTest();
    }

    // ASCソート
    @isTest static void testSortASC(){
        Test.startTest();
        wait(10);
        // テストデータ（親オブジェクトとファイルのペア）作成
        createTestData();

        List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test Document'];
        Id [] fixedSearchResults= new Id[2];
        for(Integer i=0 ; i < contentVersionList.size() ; i++){
            fixedSearchResults[i] = contentVersionList[i].Id;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Test','Account', 'asc', 500);
        System.assertEquals(2, results.size());
        System.assertEquals('Test Account', results[0].targetName);
        Test.stopTest();
    }

    // DESCソート
    @isTest static void testSortDESC(){
        Test.startTest();
        wait(10);
        // テストデータ（親オブジェクトとファイルのペア）作成
        createTestData();

        List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test Document'];
        Id [] fixedSearchResults= new Id[2];
        for(Integer i=0 ; i < contentVersionList.size() ; i++){
            fixedSearchResults[i] = contentVersionList[i].Id;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Test','Account', 'desc', 500);
        System.assertEquals(2, results.size());
        System.assertEquals('Test Account', results[1].targetName);
        Test.stopTest();
    }

    // ascでもdescでもない場合
    // ASCソート
    @isTest static void testSortOthers(){
        Test.startTest();
        wait(10);
        // テストデータ（親オブジェクトとファイルのペア）作成
        createTestData();

        List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test Document'];
        Id [] fixedSearchResults= new Id[2];
        for(Integer i=0 ; i < contentVersionList.size() ; i++){
            fixedSearchResults[i] = contentVersionList[i].Id;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Test','Account', 'test', 500);
        System.assertEquals(2, results.size());
        System.assertEquals('Test Account', results[0].targetName);
        Test.stopTest();
    }

    // limit
    @isTest static void testAccountLimit1(){
        Test.startTest();
        // テストデータ（親オブジェクトとファイルのペア）作成
        createTestData();

        List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'Test Document'];
        Id [] fixedSearchResults= new Id[2];
        for(Integer i=0 ; i < contentVersionList.size() ; i++){
            fixedSearchResults[i] = contentVersionList[i].Id;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        // Test実施 limit1
        List<CustomSearchController.Result> results = CustomSearchController.searchRecords('Test','Account', 'desc', 1);
        System.assertEquals(1, results.size());
        Test.stopTest();
    }
    // getObjectTest
    @isTest static void testGetObject(){
        Test.startTest();
        List<Account> accountList = [SELECT ID FROM Account];
        List<String> ids = new List<String>();
        for(Account a : accountList){
            ids.add(a.Id);
        }
        
        Map<ID, SObject> results = CustomSearchController.getObjectInfo('Account','Website', ids);
        for (String sKey : results.keySet()) {
            Account a = (Account)results.get(skey);
            if(a.Name == 'Test Account'){
                System.assertEquals('https://test', a.Website);
            }
            if(a.Name == 'Test Account2'){
                System.assertEquals('https://test2', a.Website);
            }
        }
        Test.stopTest();
    }

    // getObjSelectOptions 1オブジェクト
    @isTest static void testObjectOptionsOne(){
        Test.startTest();
        List<String> objList = new List<String>{'Account'};
        // テスト実施
        List<Map<String, String>> results = CustomSearchController.getObjSelectOptions(objList);
        System.assertEquals(1, results.size());
        System.assertEquals('取引先', results[0].get('label'));
        System.assertEquals('Account', results[0].get('value'));
        Test.stopTest();
    }

    // getObjSelectOptions 複数オブジェクト
    // 標準オブジェクトのAPI名を変更している場合
    @isTest static void testObjectOptionsMulti(){
        Test.startTest();
        List<String> objList = new List<String>{'Account', 'Contact'};
        // テスト実施
        List<Map<String, String>> results = CustomSearchController.getObjSelectOptions(objList);
        System.assertEquals(2, results.size());

        Map<String, sObjectType> sObjTypeMap = Schema.getGlobalDescribe();
        // ラベル名取得し比較        
        System.assertEquals(sObjTypeMap.get('Account').getDescribe().getLabel(), results[0].get('label'));
        System.assertEquals('Account', results[0].get('value'));
        System.assertEquals(sObjTypeMap.get('Contact').getDescribe().getLabel(), results[1].get('label'));
        System.assertEquals('Contact', results[1].get('value'));
        Test.stopTest();
    }

    // テストデータ生成
    @testSetup static void testSetup(){
        //Create Document Parent Record
        Account acc = new Account(Name='Test Account', Website='https://test');
        Insert acc;
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = acc.Id;
        cdl.ContentDocumentId = con.ContentDocumentId;
        cdl.shareType = 'V';
        Insert cdl;
    }

    private static void createTestData(){
        //Create Document Parent Record
        Account acc = new Account(Name='Test Account2', Website='https://test2');
        Insert acc;
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = acc.Id;
        cdl.ContentDocumentId = con.ContentDocumentId;
        cdl.shareType = 'V';
        Insert cdl;
    }

    private static void wait(Integer millisec){
        Integer start = System.Now().millisecond();
        while(System.Now().millisecond()< start+millisec){ 
        }
    }
}
