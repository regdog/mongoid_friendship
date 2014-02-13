module Mongoid
  module Friendable
    extend ActiveSupport::Concern

    included do |base|
      base.field :direct_friend_ids, type: Array, default: []
      base.field :inverse_friend_ids, type: Array, default: []
      base.field :pending_friend_ids, type: Array, default: []
      base.field :requested_friend_ids, type: Array, default: []
      base.field :blocked_direct_friend_ids, type: Array, default: []
      base.field :blocked_inverse_friend_ids, type: Array, default: []
      base.field :blocked_pending_friend_ids, type: Array, default: []
      base.field :blocked_requested_friend_ids, type: Array, default: []
    end

    # request a user to become a friend. If the operation succeeds, the method returns true, else false
    def request_friendship(user) 
      return false if friendshiped_with?(user) or user == self or blocked?(user)
      pending_friend_ids << user.id
      user.requested_friend_ids << self.id
      self.save && user.save
    end

    # approve a friendship invitation. If the operation succeeds, the method returns true, else false
    def approve_friendship(user)
      return false unless requested_friend_ids.include?(user.id) && user.pending_friend_ids.include?(self.id)
      requested_friend_ids.delete(user.id)
      user.pending_friend_ids.delete(self.id)
      inverse_friend_ids << user.id
      user.direct_friend_ids << self.id
      self.save && user.save
    end

    def friend_ids
      direct_friend_ids | inverse_friend_ids
    end

    # returns the list of approved friends
    def friends
      self.direct_friends | self.inverse_friends
    end

    def direct_friends
      self.class.find(direct_friend_ids)	
    end

    def inverse_friends
      self.class.find(inverse_friend_ids)
    end

    def pending_friends
      self.class.find(pending_friend_ids)
    end

    def requested_friends
      self.class.find(requested_friend_ids)
    end

     # return the list of the ones among its friends which are also friend with the given use
    def common_friends_with(user)
      self.friends & user.friends
    end

    # returns all common friend ids including user and me
    def common_friend_ids_with(user)
      users = common_friends_with(user)
      users << self
      users << user
      users.map(&:id).uniq
    end

    def ignore_friendship_reqeust(user)
      return false unless requested_friend_ids.include?(user.id) && user.pending_friend_ids.include?(self.id)
      requested_friend_ids.delete(user.id)
      user.pending_friend_ids.delete(self.id)
      self.save && user.save
    end

    # block a friendship
    def block_friend(user)
      if inverse_friend_ids.include?(user.id)
        inverse_friend_ids.delete(user.id)
        user.direct_friend_ids.delete(self.id)
        blocked_inverse_friend_ids << user.id
      elsif requested_friend_ids.include?(user.id)
      	requested_friend_ids.delete(user.id)
      	user.pending_friend_ids.delete(self.id)
      	blocked_requested_friend_ids << user.id
      elsif direct_friend_ids.include?(user.id)
      	direct_friend_ids.delete(user.id)
      	user.inverse_friend_ids.delete(self.id)
      	blocked_direct_friend_ids << user.id
      else
      	return false
      end

      self.save
    end

    # unblocks a friendship
    def unblock_friend(user)
      if blocked_inverse_friend_ids.include?(user.id)
        blocked_inverse_friend_ids.delete(user.id)
        user.blocked_direct_friend_ids.delete(self.id)
        inverse_friend_ids << user.id
        user.direct_friend_ids << self.id
      elsif blocked_requested_friend_ids.include?(user.id)
        blocked_requested_friend_ids.delete(user.id)
        requested_friend_ids << user.id
        user.pending_friend_ids << self.id
      elsif blocked_direct_friend_ids.include?(user.id)
        blocked_direct_friend_ids.delete(user.id)
        user.blocked_inverse_friend_ids.delete(self.id)
        direct_friend_ids << user.id
        user.inverse_friend_ids << self.id
      else
        return false
      end

      self.save && user.save
    end

    # returns the list of blocked friends
    def blocked
      blocked_ids = blocked_direct_friend_ids | blocked_inverse_friend_ids | blocked_pending_inverse_friend_ids
      self.class.find(blocked_ids)
    end

    def blocked?(user)
      (blocked_direct_friend_ids + blocked_inverse_friend_ids + blocked_requested_friend_ids).include?(user.id) or user.blocked_requested_friend_ids.include?(self.id)
    end

    def friend_with?(user)
      return false if user == self
      (direct_friend_ids | inverse_friend_ids).include?(user.id)
    end

    # checks if a current user is connected to given user
    def connected_with?(user)
      friendshiped_with?(user)	
    end

    # checks if a current user received invitation from given user
    def reqeusted_friendship_by(user)
      user.direct_friend_ids.include?(self.id) or user.pending_friend_ids.include?(self.id)
    end

    # checks if a current user invited given user
    def requested?(user)
      self.direct_friend_ids.include?(user.id) or self.pending_friend_ids.include?(user.id)
    end

    # check if any friendship exists with another user
    def friendshiped_with?(user)
      (direct_friend_ids | inverse_friend_ids | pending_friend_ids | requested_friend_ids | blocked_direct_friend_ids).include?(user.id)
    end

    # deletes a friendship
    def remove_friendship(user)
      direct_friend_ids.delete(user.id)
      user.inverse_friend_ids.delete(self.id)
      inverse_friend_ids.delete(user.id)
      user.direct_friend_ids.delete(self.id)
      pending_friend_ids.delete(user.id)
      user.requested_friend_ids.delete(self.id)
      requested_friend_ids.delete(user.id)
      user.pending_friend_ids.delete(self.id)
      self.save && user.save
    end

    # deletes all the friendships
    def delete_all_friendships
      direct_friend_ids.clear
      inverse_friend_ids.clear
      pending_friend_ids.clear
      requested_friend_ids.clear
      blocked_direct_friend_ids.clear
      blocked_inverse_friend_ids.clear
      blocked_pending_friend_ids.clear
      blocked_requested_friend_ids.clear
      self.save
    end
  end
end