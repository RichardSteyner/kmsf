global class ShopifyCheckoutBatch implements Database.Batchable<ShopifyCheckout>, Database.Stateful, Database.AllowsCallouts{
    public String instance;
    public Boolean isAll;
    public Integer pageSize;
    public String pageInfo;
    public String filterAditional; //add minimum update date
    
    global ShopifyCheckoutBatch(String instance, Boolean isAll, Integer pageSize){
        this(instance, isAll, pageSize, '');
    }
    
    global ShopifyCheckoutBatch(String instance, Boolean isAll, Integer pageSize, String pageInfo){
        this.instance = instance;
        this.isAll = isAll;
        this.pageSize = pageSize;
        this.pageInfo = pageInfo;
        filterAditional = (!isAll ? ('&updated_at_min=' + Datetime.now().addHours(-12).format('yyyy-MM-dd')) : '');
    }
    
    global List<ShopifyCheckout> start(Database.BatchableContext BC){
        String[] jsonString;
        if(String.isBlank(pageInfo))
        	jsonString = ShopifyConnection.getShopifyEntity(instance, 'checkouts', 'status=any&limit=' + pageSize + + filterAditional);
        else
            jsonString = ShopifyConnection.getShopifyEntity(instance, 'checkouts', pageInfo);
        CheckoutParser jsonCheckouts = new CheckoutParser();
       	jsonCheckouts = (CheckoutParser)json.deserialize(jsonString[0], CheckoutParser.class);
        //if(jsonCheckouts.checkouts.size()>0) initPage++; else initPage = 0;
        pageInfo = jsonString[1];
        return jsonCheckouts.checkouts;
    }
    
    global void execute(Database.BatchableContext BC, List<ShopifyCheckout> scope){
        try{
            Map<String, Opportunity> opps = new Map<String, Opportunity>();
            Map<String, OpportunityLineItem> olis = new Map<String, OpportunityLineItem>();
            Map<String, List<OpportunityLineItem>> oppItems = new Map<String, List<OpportunityLineItem>>();
            
            List<OpportunityLineItem> auxOlis;
            OpportunityLineItem objOli;
            Map<String, Product2> products = new Map<String, Product2>();
            Map<String, PricebookEntry> pbesStandard = new Map<String, PricebookEntry>();
            Map<String, PricebookEntry> pbes = new Map<String, PricebookEntry>();
            
            Map<String, Account> accounts = new Map<String, Account>();
            /*System.debug('accounts: ' + accounts);
            for(Account acc : [select Id, ShopifyID__c from Account where ShopifyID__c in: accounts.keySet()]){
                accounts.put(acc.ShopifyID__c, acc);
            }*/
                       
            List<Pricebook2> pbs = [SELECT Id, Name, IsStandard FROM Pricebook2 WHERE IsStandard = true or Name =: instance];
            String standardBookId = null;
            String instanceBookId = null;
            if(Test.isRunningTest()) standardBookId = Test.getStandardPricebookId();
            if(pbs.size()>0) {
                for(Pricebook2 pri : pbs){
                    if(pri.Name.equalsIgnoreCase(instance)) instanceBookId=pri.Id;
                    else if(pri.IsStandard) standardBookId = pri.Id;
                }
            }
            
            Map<String, String> entryIds = new Map<String, String>();
            
            Map<Decimal, String> lastOpps = new Map<Decimal, String>();
            
            String recordTypeCustomerAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer') != null ? Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId() : null;
            String recordTypeOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(instance) != null ? Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(instance).getRecordTypeId() : null;
            
            for(ShopifyCheckout item : scope){
                System.debug(item.name);
                opps.put(instance.touppercase() + '-' + item.id, new Opportunity(ShopifyID__c=instance.touppercase() + '-' + item.id, Name=String.valueOf(item.name), CloseDate=item.getCloseDate(),
                                                  StageName='Closed Lost',
                                                  Landing_Site__c=item.getLandingSite(), Order_Notes__c=item.note, LeadSource=item.source_name,
                                                  Subtotal__c=item.getSubtotal(), Taxes_Included__c=item.taxes_included, Total_Discounts__c=item.getTotalDiscounts(),
                                                  Total__c=item.getTotalPrice(), Total_Tax__c=item.getTotalTax(), Customer_ShopifyID__c=instance.touppercase() + '-' + item.getCustomerId()/*,
                                                   AccountId= (item.getCustomerId()!=null ? accountIds.get(item.getCustomerId()) : null)*/,
                                                  Discount_Codes__c=item.getDiscount_Codes(), RecordTypeId=recordTypeOpportunity));
                
                if(item.getCustomerId()!=null){
                    accounts.put(instance.touppercase() + '-' + item.getCustomerId(), new Account(Name=item.customer.first_name + ' ' + item.customer.last_name, ShopifyID__c=instance.touppercase() + '-' + item.getCustomerId(),
                                                                  	RecordTypeId=recordTypeCustomerAccount, Shopify_Type__c=instance/*, Last_Order_Id__c=item.customer.last_order_id,
                                                                  	ShippingStreet=item.getShippingStreet(), ShippingCity=item.getShippingCity(), 
                                                          			ShippingState=item.getShippingState(), ShippingPostalCode=item.getShippingZip()*/));
                    /*if(item.customer.last_order_id!=null){
                        lastOpps.put(item.customer.last_order_id, null);
                    }*/
                }
                	
                
                auxOlis = new List<OpportunityLineItem>();
                for(ShopifyCheckout.Line_Item lineItem : item.line_items){
                    objOli = new OpportunityLineItem(ShopifyID__c=instance.touppercase() + '-' + item.id + '-' + lineItem.product_id, Product_ShopifyID__c=instance.touppercase() + '-' + lineItem.product_id,
                                                     Opportunity_ShopifyID__c=instance.touppercase() + '-' + item.id, Oli_ShopifyKey__c=lineItem.key,
                                                     Quantity=lineItem.quantity, Requires_Shipping__c=lineItem.requires_shipping, UnitPrice=lineItem.getUnitPrice(),
                                                     Taxable__c=lineItem.taxable, /*Total_Discount__c=lineItem.getTotalDiscount(),*/ Total_Tax__c=lineItem.getTotalTax());
                    products.put(instance.touppercase() + '-' + lineItem.product_id, new Product2(Name=lineItem.Title, ShopifyID__c=instance.touppercase() + '-' + lineItem.product_id, 
                                                                                                  IsActive=true, Shopify_Type__c=instance));
                    
                    if(standardBookId != null ){
                        pbesStandard.put('S-' + instance.touppercase() + '-' + lineItem.product_id, new PricebookEntry(ShopifyID__c='S-' + instance.touppercase() + '-' + lineItem.product_id, 
                                                                                                        Pricebook2Id=(standardBookId), IsActive=true, UnitPrice=lineItem.getUnitPrice()));
                    	if(instanceBookId!=null){
                            pbes.put(instance.touppercase() + '-' + lineItem.product_id, new PricebookEntry(ShopifyID__c=instance.touppercase() + '-' + lineItem.product_id, 
                                                                                                        Pricebook2Id=(instanceBookId), IsActive=true, UnitPrice=lineItem.getUnitPrice()));
                        }
                    }   
                    entryIds.put(instance.touppercase() + '-' + lineItem.product_id, null);
                    olis.put(instance.touppercase() + '-' + item.id + '-' + lineItem.product_id, objOli);
                    auxOlis.add(objOli);
                }
                oppItems.put(instance.touppercase() + '-' + item.id, auxOlis);
            }
            //System.debug(products);
            System.debug(pbes);
            List<Database.UpsertResult> upsertResults;
            
            upsertResults = Database.upsert(accounts.values(), Account.ShopifyID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyOrderBatch - Account Upsert Error: ' + upsertError.getMessage());
                }
            }
            
            for(Opportunity o : opps.values()){
                if(o.Customer_ShopifyID__c!=null)
                {
                    if(accounts.get(o.Customer_ShopifyID__c)!=null && accounts.get(o.Customer_ShopifyID__c).Id!=null) 
                    	o.AccountId = accounts.get(o.Customer_ShopifyID__c).Id;
                    //System.debug('Add: ' + acc.Name + '-' + acc.Id);
                }
            }
            
            upsertResults = Database.upsert(opps.values(), Opportunity.ShopifyID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyOrderBatch - Opportunity Upsert Error: ' + upsertError.getMessage());
                }
            }
            
            /*for(Opportunity o : opps.values()){
                if(o.Id!=null)
                {
                    if(oppItems.get(o.ShopifyID__c)!=null) 
                        for(OpportunityLineItem oliA : oppItems.get(o.ShopifyID__c)){
                            oliA.OpportunityId = o.Id;
                        }
                    //System.debug('Add: ' + acc.Name + '-' + acc.Id);
                }
                else{
                    if(oppItems.get(o.ShopifyID__c)!=null) oppItems.remove(o.ShopifyID__c);
                    System.debug('Remove: ' + o.Name);
                }
            }*/
            
            for(OpportunityLineItem oliA : olis.values()){
                if(opps.get(oliA.Opportunity_ShopifyID__c)!=null && opps.get(oliA.Opportunity_ShopifyID__c).Id!=null) {
                    oliA.OpportunityId = opps.get(oliA.Opportunity_ShopifyID__c).Id;
                    //System.debug('Add: ' + acc.Name + '-' + acc.Id);
                }
                else {
                    olis.remove(oliA.ShopifyID__c);
                    System.debug('Remove: ' + oliA.ShopifyID__c);
                }
            }
            
            System.debug('entryIds: ' + entryIds);
            for(PricebookEntry pro : [select Id, ShopifyID__c from PricebookEntry where ShopifyID__c in: entryIds.keySet()]){
                entryIds.put(pro.ShopifyID__c, pro.Id);
            }
            
            for(OpportunityLineItem oliA : olis.values()){
                if(entryIds.get(oliA.Product_ShopifyID__c)!=null) {
                    oliA.PricebookEntryId = entryIds.get(oliA.Product_ShopifyID__c);
                    //System.debug('Add: ' + acc.Name + '-' + acc.Id);
                }
                else {
                    olis.remove(oliA.ShopifyID__c);
                    System.debug('Remove Oli: ' + oliA.ShopifyID__c);
                }
            }
            
            upsertResults = Database.upsert(olis.values(), OpportunityLineItem.ShopifyID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyOrderBatch - OpportunityLineItem Upsert Error: ' + upsertError.getMessage());
                }
            }
            
        }catch(Exception e){
            System.debug(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finsih ShopifyCheckoutBatch');
        if(!Test.isRunningTest()){
            if(!String.isBlank(pageInfo)) System.scheduleBatch(new ShopifyCheckoutBatch(instance, isAll, pageSize, pageInfo), 'ShopifyCheckoutBatch', 1, 100);
            /*if(isAll) ApexUtil.findEscuela(-1);
            else Database.executeBatch(new AeriesGetStudentDataChangesBatch(false, 'student'));*/
        }
    }
    
}
