// Code generated by counterfeiter. DO NOT EDIT.
package apifakes

import (
	"sync"

	"github.com/tjarratt/doit-etre-rad/backend/api"
)

type FakeAdminRepository struct {
	PhraseCountByUserUUIDStub        func() ([]api.PhraseCount, error)
	phraseCountByUserUUIDMutex       sync.RWMutex
	phraseCountByUserUUIDArgsForCall []struct{}
	phraseCountByUserUUIDReturns     struct {
		result1 []api.PhraseCount
		result2 error
	}
	phraseCountByUserUUIDReturnsOnCall map[int]struct {
		result1 []api.PhraseCount
		result2 error
	}
	invocations      map[string][][]interface{}
	invocationsMutex sync.RWMutex
}

func (fake *FakeAdminRepository) PhraseCountByUserUUID() ([]api.PhraseCount, error) {
	fake.phraseCountByUserUUIDMutex.Lock()
	ret, specificReturn := fake.phraseCountByUserUUIDReturnsOnCall[len(fake.phraseCountByUserUUIDArgsForCall)]
	fake.phraseCountByUserUUIDArgsForCall = append(fake.phraseCountByUserUUIDArgsForCall, struct{}{})
	fake.recordInvocation("PhraseCountByUserUUID", []interface{}{})
	fake.phraseCountByUserUUIDMutex.Unlock()
	if fake.PhraseCountByUserUUIDStub != nil {
		return fake.PhraseCountByUserUUIDStub()
	}
	if specificReturn {
		return ret.result1, ret.result2
	}
	return fake.phraseCountByUserUUIDReturns.result1, fake.phraseCountByUserUUIDReturns.result2
}

func (fake *FakeAdminRepository) PhraseCountByUserUUIDCallCount() int {
	fake.phraseCountByUserUUIDMutex.RLock()
	defer fake.phraseCountByUserUUIDMutex.RUnlock()
	return len(fake.phraseCountByUserUUIDArgsForCall)
}

func (fake *FakeAdminRepository) PhraseCountByUserUUIDReturns(result1 []api.PhraseCount, result2 error) {
	fake.PhraseCountByUserUUIDStub = nil
	fake.phraseCountByUserUUIDReturns = struct {
		result1 []api.PhraseCount
		result2 error
	}{result1, result2}
}

func (fake *FakeAdminRepository) PhraseCountByUserUUIDReturnsOnCall(i int, result1 []api.PhraseCount, result2 error) {
	fake.PhraseCountByUserUUIDStub = nil
	if fake.phraseCountByUserUUIDReturnsOnCall == nil {
		fake.phraseCountByUserUUIDReturnsOnCall = make(map[int]struct {
			result1 []api.PhraseCount
			result2 error
		})
	}
	fake.phraseCountByUserUUIDReturnsOnCall[i] = struct {
		result1 []api.PhraseCount
		result2 error
	}{result1, result2}
}

func (fake *FakeAdminRepository) Invocations() map[string][][]interface{} {
	fake.invocationsMutex.RLock()
	defer fake.invocationsMutex.RUnlock()
	fake.phraseCountByUserUUIDMutex.RLock()
	defer fake.phraseCountByUserUUIDMutex.RUnlock()
	copiedInvocations := map[string][][]interface{}{}
	for key, value := range fake.invocations {
		copiedInvocations[key] = value
	}
	return copiedInvocations
}

func (fake *FakeAdminRepository) recordInvocation(key string, args []interface{}) {
	fake.invocationsMutex.Lock()
	defer fake.invocationsMutex.Unlock()
	if fake.invocations == nil {
		fake.invocations = map[string][][]interface{}{}
	}
	if fake.invocations[key] == nil {
		fake.invocations[key] = [][]interface{}{}
	}
	fake.invocations[key] = append(fake.invocations[key], args)
}

var _ api.AdminRepository = new(FakeAdminRepository)