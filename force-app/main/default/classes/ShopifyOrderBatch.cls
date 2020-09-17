global class ShopifyOrderBatch implements Database.Batchable<ShopifyOrder>, Database.Stateful, Database.AllowsCallouts{
    public String instance;
    public Boolean isAll;
    public Integer pageSize;
    public String pageInfo;
    public String filterAditional; //add minimum update date
    
    global ShopifyOrderBatch(String instance, Boolean isAll, Integer pageSize){
        this(instance, isAll, pageSize, '');
    }
    
    global ShopifyOrderBatch(String instance, Boolean isAll, Integer pageSize, String pageInfo){
        this.instance = instance;
        this.isAll = isAll;
        this.pageSize = pageSize;
        this.pageInfo = pageInfo;
        filterAditional = (!isAll ? ('&updated_at_min=' + Datetime.now().addHours(-12).format('yyyy-MM-dd')) : '');
    }
    
    global List<ShopifyOrder> start(Database.BatchableContext BC){
        String[] jsonString;
        if(String.isBlank(pageInfo))
        	jsonString = ShopifyConnection.getShopifyEntity(instance, 'orders', 'status=any&limit=' + pageSize + filterAditional);
        else
            jsonString = ShopifyConnection.getShopifyEntity(instance, 'orders', pageInfo);
        OrderParser jsonOrders = new OrderParser();
       	jsonOrders = (OrderParser)json.deserialize(jsonString[0], OrderParser.class);
        //if(jsonOrders.orders.size()>0) initPage++; else initPage = 0;
        pageInfo = jsonString[1];
        return jsonOrders.orders;
    }
    
    global void execute(Database.BatchableContext BC, List<ShopifyOrder> scope){
        try{
            Map<String, Opportunity> opps = new Map<String, Opportunity>();
            Map<String, OpportunityLineItem> olis = new Map<String, OpportunityLineItem>();
            Map<String, List<OpportunityLineItem>> oppItems = new Map<String, List<OpportunityLineItem>>();
            Map<String, OpportunityContactRole> oppcontactRoles = new Map<String, OpportunityContactRole>();
            
            List<OpportunityLineItem> auxOlis;
            OpportunityLineItem objOli;
            Map<String, Product2> products = new Map<String, Product2>();
            Map<String, PricebookEntry> pbesStandard = new Map<String, PricebookEntry>();
            Map<String, PricebookEntry> pbes = new Map<String, PricebookEntry>();
            
            Map<String, Account> accounts = new Map<String, Account>();
            Map<String, Contact> contacts = new Map<String, Contact>();
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
            
            Map<String, String> lastOpps = new Map<String, String>();
            
            String recordTypeCustomerAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer') != null ? Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId() : null;
            String recordTypeCustomerContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Customer') != null ? Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Customer').getRecordTypeId() : null;
            String recordTypeOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(instance) != null ? Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(instance).getRecordTypeId() : null;
            
            for(ShopifyOrder item : scope){
                System.debug(item.order_number);
                opps.put(instance.touppercase() + '-' + item.id, new Opportunity(ShopifyID__c=instance.touppercase() + '-' + item.id, Name=String.valueOf(item.order_number), Billing_Address__c=item.getBillingAddress(),
                                                  Shipping_Address__c=item.getShippingAddress(), CloseDate=item.getCloseDate(), Cancelled_date_time__c=item.getCancelledAt(),
                                                  Loss_Reason__c=item.cancel_reason, Financial_Status__c=item.financial_status, Fulfilments_Status__c=item.fulfillment_status,
                                                  Landing_Site__c=item.getLandingSite(), Order_Notes__c=item.note, LeadSource=item.source_name, StageName='Closed Won',
                                                  Subtotal__c=item.getSubtotal(), Taxes_Included__c=item.taxes_included, Total_Discounts__c=item.getTotalDiscounts(),
                                                  Total__c=item.getTotalPrice(), Total_Tax__c=item.getTotalTax(), Customer_ShopifyID__c=instance.touppercase() + '-' + item.getCustomerId()/*,
                                                   AccountId= (item.getCustomerId()!=null ? accountIds.get(item.getCustomerId()) : null)*/,
                                                  Discount_Codes__c=item.getDiscount_Codes(), RecordTypeId=recordTypeOpportunity,
                                                  Tracking_Number__c=item.getTrackingNumber(), Tracking_Url__c=item.getTrackingUrl()));
                
                if(item.getCustomerId()!=null){
                    accounts.put(instance.touppercase() + '-' + item.getCustomerId(), new Account(Name=item.customer.first_name + ' ' + item.customer.last_name, ShopifyID__c=instance.touppercase() + '-' + item.getCustomerId(),
                                                                  	RecordTypeId=recordTypeCustomerAccount, Last_Order_Id__c=instance.touppercase() + '-' + item.customer.last_order_id,
                                                                  	ShippingStreet=item.getShippingStreet(), ShippingCity=item.getShippingCity(), 
                                                          			ShippingState=item.getShippingState(), ShippingPostalCode=item.getShippingZip(),
                                                                                                 Shopify_Type__c=instance));

                    contacts.put(instance.touppercase() + '-' + item.getCustomerId(), new Contact(ShopifyID__c=instance.touppercase() + '-' + item.getCustomerId(),         FirstName=item.customer.first_name, RecordTypeId=recordTypeCustomerContact, LastName=item.customer.last_name, Shopify_Type__c=instance));
                    
                    oppcontactRoles.put(instance.touppercase() + '-' + item.id, new OpportunityContactRole(Opportunity_Shopify_ID__c=instance.touppercase() + '-' + item.id, Contact_Shopify_ID__c=instance.touppercase() + '-' + item.getCustomerId(), IsPrimary=true));
                    
                    if(item.customer.last_order_id!=null){
                        lastOpps.put(instance.touppercase() + '-' + item.customer.last_order_id, null);
                    }
                }
                	
                
                auxOlis = new List<OpportunityLineItem>();
                for(ShopifyOrder.Line_Item lineItem : item.line_items){
                    objOli = new OpportunityLineItem(ShopifyID__c=instance.touppercase() + '-' + item.id + '-' + lineItem.product_id, Product_ShopifyID__c=instance.touppercase() + '-' + lineItem.product_id,
                                                     Opportunity_ShopifyID__c=instance.touppercase() + '-' + item.id, Oli_ShopifyID__c=instance.touppercase() + '-' + lineItem.id,
                        							 Fulfillable_Quantity__c=lineItem.fulfillable_quantity, Fulfillment_Status__c=item.fulfillment_status,
                                                     Quantity=lineItem.quantity, Requires_Shipping__c=lineItem.requires_shipping, UnitPrice=lineItem.getUnitPrice(),
                                                     Taxable__c=lineItem.taxable, Total_Discount__c=lineItem.getTotalDiscount(), Total_Tax__c=lineItem.getTotalTax());
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

            for(Account a : accounts.values()){
                if(a.Id!=null)
                {
                    if(contacts.get(a.ShopifyID__c)!=null) contacts.get(a.ShopifyID__c).AccountId=a.Id;
                    //System.debug('Add: ' + acc.Name + '-' + acc.Id);
                }
                else{
                    if(contacts.get(a.ShopifyID__c)!=null) contacts.remove(a.ShopifyID__c);
                    System.debug('Remove contact: ' + a.Name);
                }
            }
            
            upsertResults = Database.upsert(contacts.values(), Contact.ShopifyID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyOrderBatch - Contact Upsert Error: ' + upsertError.getMessage());
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
            
            for(OpportunityContactRole ocr : oppcontactRoles.values()){
                if(opps.get(ocr.Opportunity_Shopify_ID__c)!=null && opps.get(ocr.Opportunity_Shopify_ID__c).Id!=null) {
                    ocr.OpportunityId = opps.get(ocr.Opportunity_Shopify_ID__c).Id;
                    
                    if(contacts.get(ocr.Contact_Shopify_ID__c)!=null && contacts.get(ocr.Contact_Shopify_ID__c).Id!=null) {
                        ocr.ContactId = contacts.get(ocr.Contact_Shopify_ID__c).Id;
                    }
                    else {
                        oppcontactRoles.remove(ocr.Opportunity_Shopify_ID__c);
                        System.debug('Remove OCR (contact): ' + ocr.Contact_Shopify_ID__c);
                    }
                }
                else {
                    oppcontactRoles.remove(ocr.Opportunity_Shopify_ID__c);
                    System.debug('Remove OCR (opp): ' + ocr.Opportunity_Shopify_ID__c);
                }
            }

            for(OpportunityContactRole ocr : [select Id, Opportunity_Shopify_ID__c from OpportunityContactRole where Opportunity_Shopify_ID__c in: oppcontactRoles.keySet()]){
                oppcontactRoles.get(ocr.Opportunity_Shopify_ID__c).Id = ocr.Id;
            }

            upsertResults = Database.upsert(oppcontactRoles.values(), false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyOrderBatch - OpportunityContactRole Upsert Error: ' + upsertError.getMessage());
                }
            }

            
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
            System.debug('entryIds: ' + entryIds);
            
            for(OpportunityLineItem oliA : olis.values()){
                if(entryIds.get(oliA.Product_ShopifyID__c)!=null) {
                    oliA.PricebookEntryId = entryIds.get(oliA.Product_ShopifyID__c);
                    //System.debug('Add: ' + acc.Name + '-' + acc.Id);
                }
                else {
                    olis.remove(oliA.ShopifyID__c);
                    System.debug('Remove Oli: ' + oliA.ShopifyID__c + ' -->Product_ShopifyID__c' + oliA.Product_ShopifyID__c);
                }
            }
            
            upsertResults = Database.upsert(olis.values(), OpportunityLineItem.ShopifyID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyOrderBatch - OpportunityLineItem Upsert Error: ' + upsertError.getMessage());
                }
            }
            
            //Update Customer with last opp 
            for(Opportunity opp : [select Id, ShopifyID__c from Opportunity where ShopifyID__c in: lastOpps.keySet()]){
                lastOpps.put(instance.touppercase() + '-' + opp.ShopifyID__c, opp.Id);
            }
            
            for(Account acc : accounts.values()){
                if(lastOpps.get(acc.Last_Order_Id__c)!=null)
                    acc.Opportunity__c = lastOpps.get(acc.Last_Order_Id__c);
            }
            
            upsertResults = Database.upsert(accounts.values(), Account.ShopifyID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults) {
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) 
                        System.debug('ShopifyOrderBatch - Account Last Opp Upsert Error: ' + upsertError.getMessage());
                }
            }
            
        }catch(Exception e){
            System.debug(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finsih ShopifyOrderBatch: pageInfo->' + pageInfo);
        if(!Test.isRunningTest()){
            if(!String.isBlank(pageInfo)) System.scheduleBatch(new ShopifyOrderBatch(instance, isAll, pageSize, pageInfo), 'ShopifyOrderBatch', 1, 100);
            else Database.executeBatch(new ShopifyCheckoutBatch(instance, isAll, pageSize));
        }
    }
    
}
