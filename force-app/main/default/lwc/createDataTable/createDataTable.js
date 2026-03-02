import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex
import getLeads from '@salesforce/apex/ContactDataTableControllers.getAccounts';
import syncLeadsToOrgB from '@salesforce/apex/OAuthKickoff.syncLeadsToOrgB';

// UI API
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import LEAD_SOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
    
const COLUMNS = [
    { label: 'Lead Name', fieldName: 'Name' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Phone', fieldName: 'Phone', type: 'phone' },
    { label: 'Lead Source', fieldName: 'LeadSource' }
];

export default class LeadDataTable extends LightningElement {

    // UI
    columns = COLUMNS;
    data = [];
    display = [];
    
    // Filters
    searchName = '';
    leadSource = '';
    pageNo = 0;
    recordStart;
    recordEnd;
    
    // Sync status
    isSyncing = false;

    // Picklist
    leadSourceOptions = [];

    // Button label getter
    get syncButtonLabel() {
        return this.isSyncing ? 'Syncing...' : 'Sync Displayed Leads to Target Org';
    }

    /* ------------------------------------
       OBJECT INFO (for recordTypeId)
    ------------------------------------ */
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadObjectInfo;

    /* ------------------------------------
       PICKLIST VALUES
    ------------------------------------ */
    @wire(getPicklistValues, {
        recordTypeId: '$leadObjectInfo.data.defaultRecordTypeId',
        fieldApiName: LEAD_SOURCE_FIELD
    })
    wiredPicklists({ data, error }) {
        if (data) {
            this.leadSourceOptions = [
                { label: 'None', value: '' },
                ...data.values.map(item => ({
                    label: item.label,
                    value: item.value
                }))
            ];

            console.log('✅ Lead Source options:', this.leadSourceOptions);
        }               

        if (error) {
            console.error('❌ Picklist error', error);
        }
    }

    /* ------------------------------------
       LIFECYCLE
    ------------------------------------ */
    connectedCallback() {
        this.loadLeads();
        console.log('JS FILE LOADED');
    }

    /* ------------------------------------
       HANDLERS
    ------------------------------------ */
    handleNameChange(event) {
        this.searchName = event.target.value;
        this.pageNo = 0;
        this.loadLeads();
    }

    handleLeadSourceChange(event) {
        this.leadSource = event.detail.value;
        this.pageNo = 0;
        this.loadLeads();
    }

    handleNext(event) {
        this.pageNo = this.pageNo + 1;
        let maxPage = Math.floor(this.data.length / 5);
        
        if (this.pageNo > maxPage) {
            this.pageNo = maxPage;
        }
        
        this.updateDisplayRecords();
    }

    handlePrevious(event) { 
        this.pageNo = this.pageNo - 1;
        if (this.pageNo < 0) {
            this.pageNo = 0;
        }
        
        this.updateDisplayRecords();
    }

    // Sync currently displayed leads to Org B
    handleOAuthConnect() {
        console.log('🔐 Syncing displayed leads to Target Org...');
        
        // Get IDs of currently displayed leads
        const leadIdsToSync = this.display
            .filter(lead => lead && lead.Id)
            .map(lead => lead.Id);
        
        console.log('📤 Lead IDs to sync:', leadIdsToSync);
        
        if(leadIdsToSync.length === 0) {
            this.showToast('Warning', 'No leads to sync', 'warning');
            return;
        }
        
        this.isSyncing = true;
        
        syncLeadsToOrgB({ leadIds: leadIdsToSync })
            .then(result => {
                console.log('✅ Sync success:', result);
                this.showToast('Success', result, 'success');
                this.isSyncing = false;
            })
            .catch(error => {
                console.error('❌ Sync error:', error);
                const errorMessage = error.body?.message || 'Failed to sync leads';
                this.showToast('Error', errorMessage, 'error');
                this.isSyncing = false;
            });
    }

    /* ------------------------------------
       HELPER METHODS
    ------------------------------------ */
    updateDisplayRecords() {
        this.recordStart = this.pageNo * 5;
        this.recordEnd = this.recordStart + 5;
        
        this.display = [];
        for (let i = this.recordStart; i < this.recordEnd && i < this.data.length; i++) {
            if(this.data[i]) {
                this.display.push(this.data[i]);
            }
        }
        
        console.log('📄 Displaying records:', this.display.length);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
 
    /* ------------------------------------
       APEX CALL    
    ------------------------------------ */
    loadLeads() {
        getLeads({
            searchName: this.searchName,
            leadSourceName: this.leadSource,
            pageNo: this.pageNo
        })
            .then(result => {
                this.data = result;
                console.log('📊 Total leads loaded:', this.data.length);
                
                this.pageNo = 0;
                this.updateDisplayRecords();
            })
            .catch(error => {
                console.error('❌ Apex error', error);
                this.showToast('Error', 'Failed to load leads', 'error');
            });
    }
}