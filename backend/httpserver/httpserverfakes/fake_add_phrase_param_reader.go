// Code generated by counterfeiter. DO NOT EDIT.
package httpserverfakes

import (
	"net/http"
	"sync"

	"github.com/tjarratt/doit-etre-rad/backend/httpserver"
)

type FakeAddPhraseParamReader struct {
	ReadParamsFromRequestStub        func(*http.Request) (httpserver.AddPhraseParams, error)
	readParamsFromRequestMutex       sync.RWMutex
	readParamsFromRequestArgsForCall []struct {
		arg1 *http.Request
	}
	readParamsFromRequestReturns struct {
		result1 httpserver.AddPhraseParams
		result2 error
	}
	readParamsFromRequestReturnsOnCall map[int]struct {
		result1 httpserver.AddPhraseParams
		result2 error
	}
	invocations      map[string][][]interface{}
	invocationsMutex sync.RWMutex
}

func (fake *FakeAddPhraseParamReader) ReadParamsFromRequest(arg1 *http.Request) (httpserver.AddPhraseParams, error) {
	fake.readParamsFromRequestMutex.Lock()
	ret, specificReturn := fake.readParamsFromRequestReturnsOnCall[len(fake.readParamsFromRequestArgsForCall)]
	fake.readParamsFromRequestArgsForCall = append(fake.readParamsFromRequestArgsForCall, struct {
		arg1 *http.Request
	}{arg1})
	fake.recordInvocation("ReadParamsFromRequest", []interface{}{arg1})
	fake.readParamsFromRequestMutex.Unlock()
	if fake.ReadParamsFromRequestStub != nil {
		return fake.ReadParamsFromRequestStub(arg1)
	}
	if specificReturn {
		return ret.result1, ret.result2
	}
	return fake.readParamsFromRequestReturns.result1, fake.readParamsFromRequestReturns.result2
}

func (fake *FakeAddPhraseParamReader) ReadParamsFromRequestCallCount() int {
	fake.readParamsFromRequestMutex.RLock()
	defer fake.readParamsFromRequestMutex.RUnlock()
	return len(fake.readParamsFromRequestArgsForCall)
}

func (fake *FakeAddPhraseParamReader) ReadParamsFromRequestArgsForCall(i int) *http.Request {
	fake.readParamsFromRequestMutex.RLock()
	defer fake.readParamsFromRequestMutex.RUnlock()
	return fake.readParamsFromRequestArgsForCall[i].arg1
}

func (fake *FakeAddPhraseParamReader) ReadParamsFromRequestReturns(result1 httpserver.AddPhraseParams, result2 error) {
	fake.ReadParamsFromRequestStub = nil
	fake.readParamsFromRequestReturns = struct {
		result1 httpserver.AddPhraseParams
		result2 error
	}{result1, result2}
}

func (fake *FakeAddPhraseParamReader) ReadParamsFromRequestReturnsOnCall(i int, result1 httpserver.AddPhraseParams, result2 error) {
	fake.ReadParamsFromRequestStub = nil
	if fake.readParamsFromRequestReturnsOnCall == nil {
		fake.readParamsFromRequestReturnsOnCall = make(map[int]struct {
			result1 httpserver.AddPhraseParams
			result2 error
		})
	}
	fake.readParamsFromRequestReturnsOnCall[i] = struct {
		result1 httpserver.AddPhraseParams
		result2 error
	}{result1, result2}
}

func (fake *FakeAddPhraseParamReader) Invocations() map[string][][]interface{} {
	fake.invocationsMutex.RLock()
	defer fake.invocationsMutex.RUnlock()
	fake.readParamsFromRequestMutex.RLock()
	defer fake.readParamsFromRequestMutex.RUnlock()
	copiedInvocations := map[string][][]interface{}{}
	for key, value := range fake.invocations {
		copiedInvocations[key] = value
	}
	return copiedInvocations
}

func (fake *FakeAddPhraseParamReader) recordInvocation(key string, args []interface{}) {
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

var _ httpserver.AddPhraseParamReader = new(FakeAddPhraseParamReader)