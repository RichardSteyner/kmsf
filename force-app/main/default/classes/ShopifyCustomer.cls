global class ShopifyCustomer {
    
    public Long id {get; set;}
    public String email {get; set;}
    public Boolean accepts_marketing {get; set;}
    public Datetime created_at {get; set;}
    public Datetime updated_at {get; set;}
    public String first_name {get; set;}
    public String last_name {get; set;}
    public Integer orders_count {get; set;}
    public String state {get; set;}
    public String total_spent {get; set;}
    public Long last_order_id {get; set;}
    public String note {get; set;}
    public Boolean verified_email {get; set;}
    public Long multipass_identifier {get; set;}
    public Boolean tax_exempt {get; set;}
    public String phone {get; set;}
    public String tags {get; set;}
    public String last_order_name {get; set;}
    //public String _currency {get; set;}
    public Datetime accepts_marketing_updated_at {get; set;} public String marketing_opt_in_level {get; set;} public String admin_graphql_api_id {get; set;}
    public List<Address> addresses {get; set;}
    public Address default_address {get; set;}
    
    class Address {
        public Long id {get; set;}
        public Long customer_id {get; set;} public String first_name {get; set;} public String last_name {get; set;}
        public String company {get; set;}
        public String address1 {get; set;}
        public String address2 {get; set;}
        public String city {get; set;}
        public String province {get; set;}
        public String country {get; set;}
        public String zip {get; set;}
        public String phone {get; set;}
        public String name {get; set;}
        public String province_code {get; set;} public String country_code {get; set;} public String country_name {get; set;}
        //public Boolean _default {get; set;}
    }
    
    public String getLastName(){
        if(last_name != null && last_name != '')
            return last_name;
        return 'Last Null';
    }
    
    public String getName(){
        if(first_name != null && first_name != '')
            return first_name + ' ' + getLastName();
        return getLastName();
    }
    
    public String getBillingStreet(){
        if(default_address!=null)
            return default_address.address1 + ' ' + default_address.address2;
        return '';
    }
    
    public String getBillingCity(){
        if(default_address!=null)
            return default_address.city;
        return '';
    }
    
    public String getBillingState(){
        if(default_address!=null)
            return default_address.province;
        return '';
    }
    
    public String getBillingZip(){
        if(default_address!=null)
            return default_address.zip;
        return '';
    }
    
    public String getPhone(){
        if(default_address!=null)
            if (default_address.phone !=null)
            	return default_address.phone;
        if (phone != null)
            return phone;
        return '';
    }

}