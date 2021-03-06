require 'spec_helper'

describe CommunicartsController do

  let(:params) {

  '{
        "cartName": "",
        "cartNumber": "2867637",
        "category": "initiation",
        "email": "test-email@some-dot-gov.gov",
        "fromAddress": "",
        "gsaUserName": "",
        "initiationComment": "\r\n\r\nHi, this is a comment, I hope it works!\r\nThis is the second line of the comment.",
        "cartItems": [
          {
            "vendor": "DOCUMENT IMAGING DIMENSIONS, INC.",
            "description": "ROUND RING VIEW BINDER WITH INTERIOR POC",
            "url": "/advantage/catalog/product_detail.do?&oid=704213980&baseOid=&bpaNumber=GS-02F-XA002",
            "notes": "",
            "qty": "24",
            "details": "Direct Delivery 3-4 days delivered ARO",
            "socio": [],
            "partNumber": "7510-01-519-4381",
            "price": "$2.46",
            "traits": {
                "socio": [
                    "s",
                    "w"
                ],
                "features": [
                    "bpa"
                ],
                "green": "true"
            }
          },
          {
            "vendor": "OFFICE DEPOT",
            "description": "PEN,ROLLER,GELINK,G-2,X-FINE",
            "url": "/advantage/catalog/product_detail.do?&oid=703389586&baseOid=&bpaNumber=GS-02F-XA009",
            "notes": "",
            "qty": "5",
            "details": "Direct Delivery 3-4 days delivered ARO",
            "partNumber": "PIL31003",
            "price": "$10.29",
            "traits": {
                "socio": [
                    "s",
                    "w"
                ],
                "features": [
                    "bpa"
                ],
                "green": "true"
            }

          },
          {
            "vendor": "METRO OFFICE PRODUCTS",
            "description": "PAPER,LEDGER,11X8.5",
            "url": "/advantage/catalog/product_detail.do?&oid=681115589&baseOid=&bpaNumber=GS-02F-XA004",
            "notes": "",
            "qty": "3",
            "details": "Direct Delivery 3-4 days delivered ARO",
            "partNumber": "WLJ90310",
            "price": "$32.67",
            "traits": {
                "socio": [
                    "s",
                    "w"
                ],
                "features": [
                    "bpa"
                ],
                "green": "true"
            }
          }
        ]
      }'
    }

  let(:approval_group) { FactoryGirl.create(:approval_group_with_approvers, name: "anotherApprovalGroupName") }
  let(:approver) { FactoryGirl.create(:approver) }

  describe 'POST send_cart' do
    before do
      @json_params = JSON.parse(params)
      controller.stub(:total_price_from_params)
    end

    it 'creates a cart' do
      CommunicartMailer.stub_chain(:cart_notification_email, :deliver)
      Cart.should_receive(:initialize_cart_with_items)
      mock_cart = double(:cart, id: 1234)
      Cart.should_receive(:find_by).with(external_id: 2867637).and_return(mock_cart)
      mock_cart.should_receive(:decorate)
      post 'send_cart', @json_params
    end

    context 'approval group' do
      before do
        CommunicartMailer.stub_chain(:cart_notification_email, :deliver)
      end

      context 'is indicated' do
        before do
          approval_group
          @json_params['approvalGroup'] = "anotherApprovalGroupName"
        end

        it 'uses an existing approval group' do
          ApprovalGroup.should_receive(:find_by_name).with("anotherApprovalGroupName")
          post 'send_cart', @json_params
        end

        it 'invokes a mailer' do
          mock_mailer = double
          CommunicartMailer.should_receive(:cart_notification_email).and_return(mock_mailer)
          mock_mailer.should_receive(:deliver)
          post 'send_cart', @json_params
        end

        it 'creates a comment given a comment param' do
          Comment.should_receive(:create)
          post 'send_cart', @json_params
        end

        it 'does not create a comment when not given a comment param' do
          Comment.should_not receive(:create)
          @json_params['initiationComment'] = ''
          post 'send_cart', @json_params
        end

      end

      context 'is not indicated' do
        it "creates a new approval group based on the 'fromAddress' parameter sent" do
          ApprovalGroup.should_not_receive(:find_by_name)
          ApprovalGroup.should_receive(:create).with(
            {name: 'approval-group-2867637', approvers_attributes: [{ email_address: 'approver-address1234@some-dot-gov.gov' }]}
            )

          @json_params['fromAddress'] = 'approver-address1234@some-dot-gov.gov'
          post 'send_cart', @json_params
        end

        it 'creates a comment given a comment param' do
          Comment.should_receive(:create)
          post 'send_cart', @json_params
        end

        it 'does not create a comment when not given a comment param' do
          Comment.should_not receive(:create)
          @json_params['initiationComment'] = ''
          post 'send_cart', @json_params
        end

      end
    end

    it 'sets totalPrice'

  end

  describe 'POST approval_reply_received' do
    let(:cart) { FactoryGirl.create(:cart_with_approval_group) }
    let(:report) { EmailStatusReport.new(cart) }

    let(:approval_params) {
      '{
      "cartNumber": "246810",
      "category": "approvalreply",
      "attention": "",
      "fromAddress": "judy.jetson@spacelysprockets.com",
      "gsaUserName": "",
      "gsaUsername": null,
      "date": "Sun, 13 Apr 2014 18:06:15 -0400",
      "approve": "APPROVE",
      "disapprove": null,
      "comment": "Test Approval Comment"
      }'
    }
    #TODO: Replace approve/disapprove with generic action


    before do
      # Remove stub to view email layout in development through letter_opener
      CommunicartMailer.stub_chain(:approval_reply_received_email, :deliver)
      @json_approval_params = JSON.parse(approval_params)
    end

    it 'finds the cart'  do
      Cart.should_receive(:find_by).with({:external_id=>246810}).and_return(cart)
      post 'approval_reply_received', @json_approval_params
    end

    it 'invokes a mailer' do
      Cart.should_receive(:find_by).and_return(cart)
      mock_mailer = double

      CommunicartMailer.should_receive(:approval_reply_received_email).and_return(mock_mailer)
      mock_mailer.should_receive(:deliver)
      post 'approval_reply_received', @json_approval_params
    end

    it 'updates the cart status' do
      Cart.stub(:find_by).and_return(cart)
      cart.should_receive(:update_approval_status)
      post 'approval_reply_received', @json_approval_params
    end

    it 'updates the approver status'  do
      Cart.stub(:find_by).and_return(cart)
      cart.stub_chain(:approval_group, :approvers, :where).and_return([approver])
      cart.stub(:update_approval_status)
      EmailStatusReport.stub(:new).and_return(report)

      approver.should_receive(:update_attributes).with(status: 'approved')
      post 'approval_reply_received', @json_approval_params
    end
    it 'adds the comment' do
      Cart.stub(:find_by).and_return(cart)
      cart.stub_chain(:approval_group, :approvers, :where).and_return([approver])
      cart.stub(:update_approval_status)
      EmailStatusReport.stub(:new).and_return(report)

      approver.should_receive(:update_attributes).with(status: 'approved')

      ApproverComment.should_receive(:create).with(
        {comment_text: 'Test Approval Comment',approver_id: approver.id
                                                     }
            )

      post 'approval_reply_received', @json_approval_params
    end

    it 'creates a comment given a comment param' do
      Cart.stub(:find_by).and_return(cart)
      cart.stub_chain(:approval_group, :approvers, :where).and_return([approver])
      cart.stub(:update_approval_status)
      EmailStatusReport.stub(:new).and_return(report)

      ApproverComment.should_receive(:create)
      post 'approval_reply_received', @json_approval_params
    end

    it 'does not create a comment when not given a comment param' do
      Cart.stub(:find_by).and_return(cart)
      cart.stub_chain(:approval_group, :approvers, :where).and_return([approver])
      cart.stub(:update_approval_status)
      EmailStatusReport.stub(:new).and_return(report)
      @json_approval_params['comment'] = ''

      Comment.should_not receive(:create)
      post 'approval_reply_received', @json_approval_params
    end

  end
end
