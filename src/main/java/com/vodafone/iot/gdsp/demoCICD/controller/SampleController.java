package com.vodafone.iot.gdsp.demoCICD.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vodafone.iot.gdsp.demoCICD.service.SampleService;

@RestController
public class SampleController {
   
    @Autowired
    private SampleService service;
    
    /** The Constant LOGGER. */
	private static final Logger LOGGER = LoggerFactory.getLogger(SampleController.class);

	/** The Constant MYNAME. */
	private static final String MYNAME = SampleController.class.getSimpleName();

    @GetMapping("/sample/helloworld")
    public String getHelloWorld() {
    	LOGGER.info("Invoking service [{}]", MYNAME);
    	String response = service.helloWorld();
    	return response;
    }

}