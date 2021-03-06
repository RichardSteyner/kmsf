global class ShopifyCustomerBatch implements Database.Batchable<ShopifyCustomer>, Database.Stateful, Database.AllowsCallouts{
    public String instance;
    public Boolean isAll;
    public Integer pageSize;
    public String pageInfo;
    public String filterAditional; //add minimum update date
    
    global ShopifyCustomerBatch(String instance, Boolean isAll, Integer pageSize){
        this(instance, isAll, pageSize, '');
    }
    
    global ShopifyCustomerBatch(String instance, Boolean isAll, Integer pageSize, String pageInfo){
        this.instance = instance;
        this.isAll = isAll;
        this.pageSize = pageSize;
        this.pageInfo = pageInfo;
        filterAditional = (!isAll ? ('&updated_at_min=' + Datetime.now().addHours(-12).format('yyyy-MM-dd')) : '');
    }
    
    global List<ShopifyCustomer> start(Database.BatchableContext BC){
        String[] jsonString;
        if(String.isBlank(pageInfo))
        	jsonString = ShopifyConnection.getShopifyEntity(instance, 'customers', 'limit=' + pageSize + filterAditional);
        else
            jsonString = ShopifyConnection.getShopifyEntity(instance, 'customers', pageInfo);
        CustomerParser jsonCustomers = new CustomerParser();
       	jsonCustomers = (CustomerParser)json.deserialize(jsonString[0], CustomerParser.class);
        pageInfo = jsonString[1];
        //if(jsonCustomers.customers.size()>0) initPage++; else initPage = 0;
        return jsonCustomers.customers;
    }
    
    global void execute(Database.BatchableContext BC, List<ShopifyCustomer> scope){
        try{
            Map<String, Account> accounts = new Map<String, Account>();
            Map<String, Contact> contacts = new Map<String, Contact>();
            
            String recordTypeCustomerAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer') != null ? Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId() : null;
            String recordTypeCustomerContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Customer') != null ? Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Customer').getRecordTypeId() : null;
            
            
            for(ShopifyCustomer item : scope){
                System.debug(item.last_name + '-' + item.created_at + ' - ' + item.updated_at);
                accounts.put(instance.touppercase() + '-' + item.id, new Account(Name=item.getName(), ShopifyID__c=instance.touppercase() + '-' + item.id, Shopify_Notes__c=item.note, Tax_Exempt__c=item.tax_exempt,
                                                          Orders_Count__c=item.orders_count, Tags__c=item.tags, Total_Spent__c=item.total_spent, 
                                                          BillingStreet=item.getBillingStreet(), BillingCity=item.getBillingCity(), 
                                                          BillingState=item.getBillingState(), BillingPostalCode=item.getBillingZip(),
                                                 			RecordTypeId=recordTypeCustomerAccount, Shopify_Type__c=instance));
                
                	contacts.put(instance.touppercase() + '-' + item.id, new Contact(ShopifyID__c=instance.touppercase() + '-' + item.id, FirstName=item.first_name, RecordTypeId=recordTypeCustomerContact, 
                                                         LastName=item.getLastName(), Email=item.email, Phone = item.getPhone(), 
                                                      Accepts_Marketing__c=item.accepts_marketing, Shopify_Type__c=instance));
            }
            System.debug(accounts);
            System.debug(contacts);
            List<Database.UpsertResult> upsertResults;
            
            upsertResults = Database.upsert(accounts.values(), Account.ShopifyID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyCustomerBatch - Account Upsert Error: ' + upsertError.getMessage());
                }
            }
            
            for(Account a : accounts.values()){
                if(a.Id!=null)
                {
                    if(contacts.get(a.ShopifyID__c)!=null) contacts.get(a.ShopifyID__c).AccountId=a.Id;
                    //System.debug('Add: ' + acc.Name + '-' + acc.Id);
                }
                else{
                    if(contacts.get(a.ShopifyID__c)!=null) contacts.remove(a.ShopifyID__c);
                    System.debug('Remove: ' + a.Name);
                }
            }
            
            upsertResults = Database.upsert(contacts.values(), Contact.ShopifyID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyCustomerBatch - Contact Upsert Error: ' + upsertError.getMessage());
                }
            }
        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finsih ShopifyCustomerBatch: pageInfo->' + pageInfo);
        if(!Test.isRunningTest()){
            if(!String.isBlank(pageInfo)) System.scheduleBatch(new ShopifyCustomerBatch(instance, isAll, pageSize, pageInfo), 'ShopifyCustomerBatch', 1, 100);
            else Database.executeBatch(new ShopifyProductBatch(instance, isAll, pageSize));
        }
    }
    
}
